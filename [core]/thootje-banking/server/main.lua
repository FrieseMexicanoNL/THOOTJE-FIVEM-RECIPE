local lastTransfer = {}
local requestWindow = {}

local function log(...)
    if Config.Debug then print('^3[thootje-banking]^7', ...) end
end

local function notify(src, message, kind)
    TriggerClientEvent('thootje-banking:client:notify', src, message, kind or 'info')
end

local function getCharacterIdentifier(src)
    if Config.IdentifierMode == 'license' then
        for _, identifier in ipairs(GetPlayerIdentifiers(src)) do
            if identifier:sub(1, 8) == 'license:' then return identifier end
        end
    end

    local ok, data = pcall(function()
        return exports[Config.CoreResource]:GetPlayerData(src)
    end)
    if ok and type(data) == 'table' then
        local nested = data.PlayerData or data.playerData or data
        for _, field in ipairs(Config.IdentifierFields) do
            local value = nested[field]
            if value ~= nil and tostring(value) ~= '' then
                return tostring(value)
            end
        end
    end

    -- Fallback voorkomt dat een speler zonder core-data geen bank kan openen.
    -- Voor multicharacter-servers moet de core character-id export hierboven beschikbaar zijn.
    for _, identifier in ipairs(GetPlayerIdentifiers(src)) do
        if identifier:sub(1, 8) == 'license:' then return identifier end
    end
    return nil
end

local function accountNumberExists(number)
    return MySQL.scalar.await('SELECT id FROM thootje_bank_accounts WHERE account_number = ?', { number }) ~= nil
end

local function makeAccountNumber()
    for _ = 1, 30 do
        local digits = ''
        for i = 1, Config.AccountNumberLength do digits = digits .. tostring(math.random(0, 9)) end
        local number = Config.AccountPrefix .. digits
        if not accountNumberExists(number) then return number end
    end
    error('Could not generate unique bank account number')
end

local function ensureAccount(identifier)
    local account = MySQL.single.await('SELECT * FROM thootje_bank_accounts WHERE owner_identifier = ?', { identifier })
    if account then return account end

    local number = makeAccountNumber()
    local id = MySQL.insert.await([[
        INSERT INTO thootje_bank_accounts (owner_identifier, account_number, account_name, balance)
        VALUES (?, ?, ?, ?)
    ]], { identifier, number, Config.Account.Name, Config.Account.InitialBalance })
    if not id then return nil end
    account = MySQL.single.await('SELECT * FROM thootje_bank_accounts WHERE id = ?', { id })
    if account and tonumber(account.balance) > 0 then
        MySQL.insert.await([[
            INSERT INTO thootje_bank_transactions
            (account_id, transaction_type, amount, balance_after, description, reference)
            VALUES (?, 'deposit', ?, ?, 'Openingssaldo', ?)
        ]], { account.id, account.balance, account.balance, ('OPEN-%s'):format(account.id) })
    end
    return account
end

local function getAccount(src)
    local identifier = getCharacterIdentifier(src)
    if not identifier then return nil end
    return ensureAccount(identifier), identifier
end

local function getDisplayName(src)
    return GetPlayerName(src) or ('Speler %s'):format(src)
end

local function formatAccount(account)
    return {
        id = tonumber(account.id),
        number = account.account_number,
        name = account.account_name,
        balance = tonumber(account.balance) or 0,
        currency = Config.Currency,
        symbol = Config.CurrencySymbol
    }
end

local function isRateLimited(src)
    local now = os.time()
    requestWindow[src] = requestWindow[src] or { start = now, count = 0 }
    local w = requestWindow[src]
    if now - w.start >= 60 then w.start, w.count = now, 0 end
    w.count = w.count + 1
    return w.count > Config.Security.MaxRequestsPerMinute
end

local function getHistory(accountId)
    return MySQL.query.await([[
        SELECT transaction_type AS type, amount, balance_after AS balanceAfter,
               counterparty_account AS counterpartyAccount, description, reference, created_at AS createdAt
        FROM thootje_bank_transactions
        WHERE account_id = ?
        ORDER BY id DESC LIMIT ?
    ]], { accountId, Config.TransactionHistory }) or {}
end

RegisterNetEvent('thootje-banking:server:requestData', function()
    local src = source
    if isRateLimited(src) then return end
    local account = getAccount(src)
    if not account then
        notify(src, 'Je bankrekening kon niet worden geladen. Controleer de THOOTJE-CORE koppeling.', 'error')
        return
    end
    TriggerClientEvent('thootje-banking:client:openData', src, {
        bankName = Config.UI.BankName,
        tagline = Config.UI.Tagline,
        account = formatAccount(account),
        history = getHistory(account.id),
        maxTransfer = Config.MaxTransfer,
        transferFee = Config.TransferFee
    })
end)

RegisterNetEvent('thootje-banking:server:transfer', function(targetNumber, amount, description)
    local src = source
    if isRateLimited(src) then return end

    local now = os.time()
    if lastTransfer[src] and now - lastTransfer[src] < Config.Security.TransferCooldownSeconds then
        return notify(src, 'Wacht even voordat je opnieuw overboekt.', 'error')
    end
    lastTransfer[src] = now

    targetNumber = tostring(targetNumber or ''):upper():gsub('%s+', '')
    amount = math.floor(tonumber(amount) or 0)
    description = tostring(description or ''):sub(1, Config.MaxReasonLength):gsub('[<>]', '')

    if #targetNumber < 5 or #targetNumber > 32 then return notify(src, 'Vul een geldig rekeningnummer in.', 'error') end
    if amount < Config.MinTransfer or amount > Config.MaxTransfer then return notify(src, 'Dit bedrag valt buiten de toegestane limieten.', 'error') end

    local sender, senderIdentifier = getAccount(src)
    if not sender then return notify(src, 'Je rekening is niet beschikbaar.', 'error') end
    local recipient = MySQL.single.await('SELECT * FROM thootje_bank_accounts WHERE account_number = ?', { targetNumber })
    if not recipient then return notify(src, 'Deze bankrekening bestaat niet.', 'error') end
    if tonumber(sender.id) == tonumber(recipient.id) and not Config.Account.AllowSelfTransfer then
        return notify(src, 'Je kunt niet naar je eigen rekening overboeken.', 'error')
    end

    local total = amount + Config.TransferFee
    local reference = ('TH-%s-%04d'):format(os.date('%y%m%d%H%M%S'), math.random(0, 9999))
    local senderName = getDisplayName(src)
    local recipientName = 'Andere rekening'

    -- Eén atomische UPDATE wijzigt beide rekeningen alleen als de afzender genoeg saldo heeft.
    -- Zo kan de ontvanger nooit geld krijgen wanneer de afschrijving niet lukt.
    local affected = MySQL.update.await([[
        UPDATE thootje_bank_accounts
        SET balance = CASE
            WHEN id = ? THEN balance - ?
            WHEN id = ? THEN balance + ?
            ELSE balance
        END
        WHERE id IN (?, ?)
          AND (SELECT balance FROM (SELECT balance FROM thootje_bank_accounts WHERE id = ?) AS sender_balance) >= ?
    ]], { sender.id, total, recipient.id, amount, sender.id, recipient.id, sender.id, total })

    if not affected or affected ~= 2 then
        return notify(src, 'Je hebt onvoldoende saldo of de overboeking kon niet worden uitgevoerd.', 'error')
    end

    local senderFresh = MySQL.single.await('SELECT * FROM thootje_bank_accounts WHERE id = ?', { sender.id })
    local recipientFresh = MySQL.single.await('SELECT * FROM thootje_bank_accounts WHERE id = ?', { recipient.id })
    if not senderFresh or not recipientFresh then
        log('Account missing after transfer', sender.id, recipient.id)
        return notify(src, 'De rekeninggegevens konden niet worden bijgewerkt. Neem contact op met staff.', 'error')
    end

    MySQL.insert.await([[
        INSERT INTO thootje_bank_transactions
        (account_id, transaction_type, amount, balance_after, counterparty_account, description, reference)
        VALUES (?, 'transfer_out', ?, ?, ?, ?, ?)
    ]], { sender.id, amount, senderFresh.balance, recipient.account_number, description ~= '' and description or 'Overboeking', reference })
    MySQL.insert.await([[
        INSERT INTO thootje_bank_transactions
        (account_id, transaction_type, amount, balance_after, counterparty_account, description, reference)
        VALUES (?, 'transfer_in', ?, ?, ?, ?, ?)
    ]], { recipient.id, amount, recipientFresh.balance, sender.account_number, description ~= '' and description or 'Ontvangen overboeking', reference })

    TriggerClientEvent('thootje-banking:client:refreshBalance', src, formatAccount(senderFresh), getHistory(senderFresh.id))
    notify(src, ('Je hebt %s%s overgemaakt naar %s.'):format(Config.CurrencySymbol, amount, targetNumber), 'success')

    -- Ontvanger krijgt alleen een melding wanneer die online is.
    for _, playerId in ipairs(GetPlayers()) do
        local pid = tonumber(playerId)
        if pid and pid ~= src then
            local targetIdentifier = getCharacterIdentifier(pid)
            if targetIdentifier and targetIdentifier == recipient.owner_identifier then
                notify(pid, ('Je hebt %s%s ontvangen.'):format(Config.CurrencySymbol, amount), 'success')
                local fresh = MySQL.single.await('SELECT * FROM thootje_bank_accounts WHERE id = ?', { recipient.id })
                if fresh then TriggerClientEvent('thootje-banking:client:refreshBalance', pid, formatAccount(fresh), getHistory(fresh.id)) end
                break
            end
        end
    end
end)

RegisterNetEvent('thootje-banking:server:renameAccount', function(name)
    local src = source
    if isRateLimited(src) then return end
    name = tostring(name or ''):gsub('[<>]', ''):sub(1, 32)
    if #name < 3 then return notify(src, 'De rekeningnaam moet minimaal 3 tekens bevatten.', 'error') end
    local account = getAccount(src)
    if not account then return end
    MySQL.update.await('UPDATE thootje_bank_accounts SET account_name = ? WHERE id = ?', { name, account.id })
    local fresh = MySQL.single.await('SELECT * FROM thootje_bank_accounts WHERE id = ?', { account.id })
    TriggerClientEvent('thootje-banking:client:refreshBalance', src, formatAccount(fresh), getHistory(fresh.id))
    notify(src, 'Je rekeningnaam is aangepast.', 'success')
end)

AddEventHandler('playerDropped', function()
    lastTransfer[source] = nil
    requestWindow[source] = nil
end)

exports('GetBankBalance', function(src)
    local account = getAccount(src)
    return account and tonumber(account.balance) or 0
end)

exports('AddBankMoney', function(src, amount, reason)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end
    local account = getAccount(src)
    if not account then return false end
    local updated = MySQL.update.await('UPDATE thootje_bank_accounts SET balance = balance + ? WHERE id = ?', { amount, account.id })
    if not updated or updated < 1 then return false end
    local fresh = MySQL.single.await('SELECT * FROM thootje_bank_accounts WHERE id = ?', { account.id })
    MySQL.insert.await([[
        INSERT INTO thootje_bank_transactions (account_id, transaction_type, amount, balance_after, description, reference)
        VALUES (?, 'deposit', ?, ?, ?, ?)
    ]], { account.id, amount, fresh.balance, tostring(reason or 'Bijschrijving'):sub(1, 120), ('ADD-%s-%s'):format(account.id, os.time()) })
    TriggerClientEvent('thootje-banking:client:refreshBalance', src, formatAccount(fresh), getHistory(fresh.id))
    return true
end)

exports('RemoveBankMoney', function(src, amount, reason)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end
    local account = getAccount(src)
    if not account then return false end
    local affected = MySQL.update.await('UPDATE thootje_bank_accounts SET balance = balance - ? WHERE id = ? AND balance >= ?', { amount, account.id, amount })
    if not affected or affected < 1 then return false end
    local fresh = MySQL.single.await('SELECT * FROM thootje_bank_accounts WHERE id = ?', { account.id })
    MySQL.insert.await([[
        INSERT INTO thootje_bank_transactions (account_id, transaction_type, amount, balance_after, description, reference)
        VALUES (?, 'withdraw', ?, ?, ?, ?)
    ]], { account.id, amount, fresh.balance, tostring(reason or 'Afschrijving'):sub(1, 120), ('REM-%s-%s'):format(account.id, os.time()) })
    TriggerClientEvent('thootje-banking:client:refreshBalance', src, formatAccount(fresh), getHistory(fresh.id))
    return true
end)
