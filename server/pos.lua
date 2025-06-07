local QBX = exports['qb-core']:GetCoreObject()
local transactionLogs = {}

-- ==================== BANKING INTERFACE ====================
local BankingInterface = {}

-- Get account money
function BankingInterface.getAccountMoney(accountId)
    if not accountId then
        if Config.Debug then
            print("[POS] Warning: Nil accountId passed to getAccountMoney")
        end
        return 0
    end
    
    -- For personal accounts, try QBX first
    local player = QBX.Functions.GetPlayerByCitizenId(accountId)
    if player then
        return player.PlayerData.money.bank or 0
    end
    
    -- Try Renewed-Banking
    local balance = 0
    pcall(function()
        balance = exports['Renewed-Banking']:getAccountMoney(accountId) or 0
    end)
    
    return balance
end

-- Add money to account
function BankingInterface.addAccountMoney(accountId, amount)
    if not accountId then
        if Config.Debug then
            print("[POS] Warning: Nil accountId passed to addAccountMoney")
        end
        return false
    end
    
    local success = false
    pcall(function()
        success = exports['Renewed-Banking']:addAccountMoney(accountId, amount)
    end)
    
    if Config.Debug then
        print("[POS] Adding " .. amount .. " to " .. accountId .. ": " .. tostring(success))
    end
    
    return success
end

-- Remove money from player
function BankingInterface.removePlayerMoney(playerId, amount)
    local player = QBX.Functions.GetPlayer(playerId)
    if not player then return false end
    
    if (player.PlayerData.money.bank or 0) < amount then
        return false
    end
    
    return player.Functions.RemoveMoney('bank', amount, "POS transaction")
end

-- Create transaction record
function BankingInterface.createTransaction(fromAccount, toAccount, amount, message)
    if not Config.POS.EnableBankHistory then return true end
    
    local success = false
    pcall(function()
        -- Create withdrawal transaction
        local transID = exports['Renewed-Banking']:handleTransaction(
            fromAccount, 
            "Personal Account", 
            amount, 
            message, 
            "Customer", 
            Config.POS.BusinessNames[toAccount] or toAccount,
            "withdraw"
        )
        
        if transID then
            -- Create deposit transaction
            exports['Renewed-Banking']:handleTransaction(
                toAccount, 
                Config.POS.BusinessNames[toAccount] or toAccount .. " Account", 
                amount, 
                message, 
                "Customer", 
                Config.POS.BusinessNames[toAccount] or toAccount,
                "deposit",
                transID.trans_id
            )
            success = true
        end
    end)
    
    return success
end

-- ==================== UTILITY FUNCTIONS ====================

-- Calculate tax
local function calculateTax(amount)
    local taxRate = Config.POS.TaxRate or 0
    return math.floor(amount * (taxRate / 100))
end

-- Log transaction
local function logTransaction(data)
    if Config.Debug then
        print('[POS] Transaction logged: ' .. json.encode(data))
    end
    
    table.insert(transactionLogs, data)
    
    -- Keep only last 100 transactions in memory
    if #transactionLogs > 100 then
        table.remove(transactionLogs, 1)
    end
    
    -- Save to database if enabled
    if Config.POS.SaveTransactionsToDB then
        MySQL.insert('INSERT INTO `restaurant_pos_transactions` (business, customer, amount, tax, description, employee, created_at) VALUES (?, ?, ?, ?, ?, ?, NOW())', 
            {data.business, data.customer, data.amount, data.tax, data.description, data.employee}
        )
    end
end

-- ==================== DATABASE INITIALIZATION ====================
if Config.POS.SaveTransactionsToDB then
    CreateThread(function()
        MySQL.query([[
            CREATE TABLE IF NOT EXISTS `restaurant_pos_transactions` (
                `id` INT AUTO_INCREMENT PRIMARY KEY,
                `business` VARCHAR(50) NOT NULL,
                `customer` VARCHAR(50) NOT NULL,
                `amount` INT NOT NULL,
                `tax` INT DEFAULT 0,
                `description` VARCHAR(255) NOT NULL,
                `employee` VARCHAR(50) NOT NULL,
                `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                INDEX idx_business (business),
                INDEX idx_created (created_at)
            )
        ]])
    end)
end

-- ==================== CALLBACKS ====================

-- Get nearby player options
lib.callback.register('eb-template:pos:getNearbyPlayerOptions', function(source, playerIds)
    local options = {}
    
    for _, playerId in ipairs(playerIds) do
        local targetPlayer = QBX.Functions.GetPlayer(playerId)
        
        if targetPlayer then
            local playerName = targetPlayer.PlayerData.charinfo.firstname .. " " .. targetPlayer.PlayerData.charinfo.lastname
            local playerBalance = targetPlayer.PlayerData.money.bank or 0
            
            table.insert(options, {
                title = playerName,
                value = playerId,
                description = 'ID: ' .. playerId .. ' | Balance: $' .. lib.math.groupdigits(playerBalance)
            })
        end
    end
    
    -- Sort by name
    table.sort(options, function(a, b)
        return a.title < b.title
    end)
    
    return options
end)

-- Create POS transaction
lib.callback.register('eb-template:pos:createTransaction', function(source, data)
    local src = source
    local player = QBX.Functions.GetPlayer(src)
    
    if not player then 
        return false, "Authentication failed"
    end
    
    -- Validate employee is on duty and has correct job
    if not player.PlayerData.job.onduty then
        return false, "You must be on duty to use the POS"
    end
    
    if player.PlayerData.job.name ~= data.business then
        return false, "You don't have permission to use this POS"
    end
    
    -- Validate data
    if not data.target or not data.amount or not data.description then
        return false, "Missing required information"
    end
    
    -- Get target player
    local targetId = tonumber(data.target)
    if not targetId then
        return false, "Invalid customer ID"
    end
    
    local target = QBX.Functions.GetPlayer(targetId)
    if not target then
        return false, "Customer not found"
    end
    
    -- Check amount validity
    if data.amount <= 0 then
        return false, "Amount must be greater than 0"
    end
    
    -- Calculate tax
    local tax = calculateTax(data.amount)
    local totalAmount = data.amount + tax
    
    -- Check if customer has enough money
    local customerBalance = target.PlayerData.money.bank or 0
    if customerBalance < totalAmount then
        return false, "Customer has insufficient funds ($" .. lib.math.groupdigits(customerBalance) .. " available)"
    end
    
    -- Process payment - Remove from customer
    local paymentSuccess = BankingInterface.removePlayerMoney(targetId, totalAmount)
    if not paymentSuccess then
        return false, "Payment processing failed"
    end
    
    -- Add money to business account
    local businessAccount = data.business
    local depositSuccess = BankingInterface.addAccountMoney(businessAccount, data.amount)
    
    if not depositSuccess then
        -- Refund customer if deposit fails
        target.Functions.AddMoney('bank', totalAmount, "POS refund")
        return false, "Failed to deposit to business account"
    end
    
    -- Add tax to government account if applicable
    if tax > 0 and Config.POS.TaxAccount then
        BankingInterface.addAccountMoney(Config.POS.TaxAccount, tax)
    end
    
    -- Create transaction records
    local transactionMessage = "POS: " .. data.description
    BankingInterface.createTransaction(
        target.PlayerData.citizenid,
        businessAccount,
        totalAmount,
        transactionMessage
    )
    
    -- Generate transaction ID
    local transactionId = os.time() .. math.random(1000, 9999)
    
    -- Log transaction
    logTransaction({
        id = transactionId,
        business = data.business,
        customer = target.PlayerData.citizenid,
        amount = data.amount,
        tax = tax,
        total = totalAmount,
        description = data.description,
        employee = player.PlayerData.citizenid,
        employee_name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
        timestamp = os.time()
    })
    
    -- Notify customer
    lib.notify(targetId, {
        title = 'Payment Processed',
        description = string.format('You paid $%s to %s\nTax: $%s', 
            lib.math.groupdigits(totalAmount), 
            Config.POS.BusinessNames[data.business] or data.business,
            lib.math.groupdigits(tax)
        ),
        type = 'success',
        position = Config.NotificationPosition,
        icon = 'fas fa-credit-card'
    })
    
    -- Notify employee with breakdown
    lib.notify(src, {
        title = 'Transaction Complete',
        description = string.format('Received $%s from %s\nSubtotal: $%s | Tax: $%s', 
            lib.math.groupdigits(totalAmount),
            target.PlayerData.charinfo.firstname .. ' ' .. target.PlayerData.charinfo.lastname,
            lib.math.groupdigits(data.amount),
            lib.math.groupdigits(tax)
        ),
        type = 'success',
        position = Config.NotificationPosition,
        icon = 'fas fa-cash-register'
    })
    
    -- Discord webhook if configured
    if Config.DiscordWebhook and Config.DiscordWebhook ~= '' then
        local embed = {
            {
                title = 'POS Transaction',
                fields = {
                    {name = 'Employee', value = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname, inline = true},
                    {name = 'Customer', value = target.PlayerData.charinfo.firstname .. ' ' .. target.PlayerData.charinfo.lastname, inline = true},
                    {name = 'Amount', value = '$' .. lib.math.groupdigits(totalAmount) .. ' (Tax: $' .. lib.math.groupdigits(tax) .. ')', inline = true},
                    {name = 'Description', value = data.description, inline = false},
                    {name = 'Transaction ID', value = transactionId, inline = true},
                    {name = 'Time', value = os.date('%Y-%m-%d %H:%M:%S'), inline = true}
                },
                color = 5763719, -- Green
                footer = {
                    text = Config.RestaurantLabel .. ' POS System'
                }
            }
        }
        
        PerformHttpRequest(Config.DiscordWebhook, function(err, text, headers) end, 'POST', json.encode({
            username = Config.RestaurantLabel .. ' POS',
            embeds = embed
        }), { ['Content-Type'] = 'application/json' })
    end
    
    return true, transactionId
end)

-- Get business transactions (for managers)
lib.callback.register('eb-template:pos:getTransactions', function(source, business, limit)
    local src = source
    local player = QBX.Functions.GetPlayer(src)
    
    if not player then return {} end
    
    -- Check if player is a manager
    if player.PlayerData.job.name ~= business or player.PlayerData.job.grade.level < Config.POS.ManagerGradeLevel then
        return {}
    end
    
    limit = limit or 50
    
    -- Get recent transactions from memory
    local transactions = {}
    local count = 0
    
    for i = #transactionLogs, 1, -1 do
        local log = transactionLogs[i]
        if log.business == business then
            table.insert(transactions, log)
            count = count + 1
            if count >= limit then break end
        end
    end
    
    -- If we have database storage enabled, also get from DB if needed
    if Config.POS.SaveTransactionsToDB and #transactions < limit then
        local dbTransactions = MySQL.query.await(
            'SELECT * FROM `restaurant_pos_transactions` WHERE `business` = ? ORDER BY `created_at` DESC LIMIT ?',
            {business, limit}
        )
        
        if dbTransactions then
            for _, trans in ipairs(dbTransactions) do
                -- Convert DB format to our format
                table.insert(transactions, {
                    id = trans.id,
                    business = trans.business,
                    customer = trans.customer,
                    amount = trans.amount,
                    tax = trans.tax,
                    total = trans.amount + trans.tax,
                    description = trans.description,
                    employee = trans.employee,
                    employee_name = 'Employee #' .. trans.employee, -- We don't store names in DB
                    timestamp = trans.created_at
                })
            end
        end
    end
    
    return transactions
end)

-- Command to view POS stats (manager only)
lib.addCommand('posstats', {
    help = 'View POS statistics (Manager only)',
    params = {
        {
            name = 'days',
            type = 'number',
            help = 'Number of days to look back (default: 7)',
            optional = true
        }
    },
    restricted = false
}, function(source, args, raw)
    local src = source
    local player = QBX.Functions.GetPlayer(src)
    
    if not player or player.PlayerData.job.name ~= Config.RestaurantJob or player.PlayerData.job.grade.level < Config.POS.ManagerGradeLevel then
        lib.notify(src, {
            title = Config.RestaurantLabel,
            description = 'You don\'t have permission to view POS stats',
            type = 'error',
            position = Config.NotificationPosition
        })
        return
    end
    
    local days = args.days or 7
    local totalSales = 0
    local totalTax = 0
    local transactionCount = 0
    
    -- Calculate from in-memory logs
    local cutoffTime = os.time() - (days * 24 * 60 * 60)
    
    for _, log in ipairs(transactionLogs) do
        if log.business == Config.RestaurantJob and log.timestamp >= cutoffTime then
            totalSales = totalSales + log.amount
            totalTax = totalTax + log.tax
            transactionCount = transactionCount + 1
        end
    end
    
    -- Send stats to player
    TriggerClientEvent('chat:addMessage', src, {
        template = '<div style="padding: 0.5vw; margin: 0.5vw; background-color: rgba(0, 0, 0, 0.6); border-radius: 3px;"><b>{0} POS Statistics ({1} days)</b><br>Total Sales: ${2}<br>Tax Collected: ${3}<br>Transactions: {4}<br>Average Sale: ${5}</div>',
        args = {
            Config.RestaurantLabel,
            days,
            lib.math.groupdigits(totalSales),
            lib.math.groupdigits(totalTax),
            transactionCount,
            transactionCount > 0 and lib.math.groupdigits(math.floor(totalSales / transactionCount)) or '0'
        }
    })
end)

-- Get daily report (manager function)
lib.callback.register('eb-template:pos:getDailyReport', function(source)
    local src = source
    local player = QBX.Functions.GetPlayer(src)
    
    if not player or player.PlayerData.job.name ~= Config.RestaurantJob or player.PlayerData.job.grade.level < Config.POS.ManagerGradeLevel then
        return nil
    end
    
    -- Calculate today's stats
    local todayStart = os.time({
        year = os.date("%Y"),
        month = os.date("%m"),
        day = os.date("%d"),
        hour = 0,
        min = 0,
        sec = 0
    })
    
    local totalSales = 0
    local totalTax = 0
    local transactionCount = 0
    
    for _, log in ipairs(transactionLogs) do
        if log.business == Config.RestaurantJob and log.timestamp >= todayStart then
            totalSales = totalSales + log.amount
            totalTax = totalTax + log.tax
            transactionCount = transactionCount + 1
        end
    end
    
    return {
        totalSales = totalSales,
        totalTax = totalTax,
        transactionCount = transactionCount,
        averageSale = transactionCount > 0 and math.floor(totalSales / transactionCount) or 0
    }
end)

-- Export functions
exports('getPOSTransactionLogs', function(business)
    local logs = {}
    for _, log in ipairs(transactionLogs) do
        if not business or log.business == business then
            table.insert(logs, log)
        end
    end
    return logs
end)