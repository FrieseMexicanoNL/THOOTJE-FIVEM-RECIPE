local function identifier(src) return Config.Identifier(src) end
local function playerName(src) return Config.PlayerName(src) end
local function notify(src, msg) TriggerClientEvent('thootje-society:client:notify', src, msg) end

local function getPlayerSociety(src)
    local id = identifier(src)
    if not id then return nil end
    local row = MySQL.single.await('SELECT * FROM thootje_society_employees WHERE identifier = ? LIMIT 1', { id })
    if not row then return nil end
    return row, Societies[row.society]
end

local function isBoss(row, society)
    return row and society and society.bossGrades[tonumber(row.grade)] == true
end

local function getAccount(society)
    return MySQL.single.await('SELECT * FROM thootje_society_accounts WHERE society = ?', { society })
end

local function ensureAccounts()
    for name, data in pairs(Societies) do
        MySQL.insert.await('INSERT IGNORE INTO thootje_society_accounts (society, account_number, balance) VALUES (?, ?, 0)', { name, data.account })
    end
end

local function logTransaction(society, src, kind, amount, desc, balance)
    MySQL.insert.await([[
        INSERT INTO thootje_society_transactions
        (society, actor_identifier, actor_name, transaction_type, amount, description, balance_after)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], { society, identifier(src) or 'system', src and playerName(src) or 'Systeem', kind, amount, desc, balance })
end

local function bankCall(exportName, src, amount)
    if not GetResourceState(Config.BankingResource):find('started') then return false, 'Banking-resource is niet gestart.' end
    local ok, result = pcall(function()
        return exports[Config.BankingResource][exportName](src, amount)
    end)
    if not ok then return false, 'Banking-export ontbreekt: ' .. exportName end
    if result == false then return false, 'Onvoldoende saldo of banktransactie geweigerd.' end
    return true
end

local function getBankBalance(src)
    if GetResourceState(Config.BankingResource):find('started') then
        local ok, result = pcall(function()
            return exports[Config.BankingResource][Config.Banking.GetBankMoneyExport](src)
        end)
        if ok and tonumber(result) then return tonumber(result) end
    end
    return nil
end

local function gradeList(society)
    local list = {}
    for grade, label in pairs(society.grades) do
        list[#list + 1] = { value = tonumber(grade), label = label }
    end
    table.sort(list, function(a, b) return a.value < b.value end)
    return list
end

local function updateClient(src)
    local row, society = getPlayerSociety(src)
    if not row or not society then return end
    local account = getAccount(row.society)
    local employees = MySQL.query.await('SELECT id, player_name, grade, salary, hired_at FROM thootje_society_employees WHERE society = ? ORDER BY grade DESC, player_name ASC', { row.society })
    local history = MySQL.query.await('SELECT actor_name, transaction_type, amount, description, balance_after, created_at FROM thootje_society_transactions WHERE society = ? ORDER BY id DESC LIMIT ?', { row.society, Config.TransactionHistory })
    local boss = isBoss(row, society)
    TriggerClientEvent('thootje-society:client:update', src, {
        society = row.society, label = society.label, type = society.type,
        grade = row.grade, gradeLabel = society.grades[tonumber(row.grade)] or 'Onbekend',
        boss = boss, grades = gradeList(society), balance = account and account.balance or 0,
        accountNumber = account and account.account_number or society.account,
        employees = boss and employees or {}, history = history or {}
    })
end

local function openFor(src)
    local row, society = getPlayerSociety(src)
    if not row or not society then return notify(src, 'Je bent niet in dienst bij een bedrijf.') end
    local account = getAccount(row.society)
    local employees = MySQL.query.await('SELECT id, player_name, grade, salary, hired_at FROM thootje_society_employees WHERE society = ? ORDER BY grade DESC, player_name ASC', { row.society })
    local history = MySQL.query.await('SELECT actor_name, transaction_type, amount, description, balance_after, created_at FROM thootje_society_transactions WHERE society = ? ORDER BY id DESC LIMIT ?', { row.society, Config.TransactionHistory })
    local boss = isBoss(row, society)
    TriggerClientEvent('thootje-society:client:open', src, {
        society = row.society, label = society.label, type = society.type,
        grade = row.grade, gradeLabel = society.grades[tonumber(row.grade)] or 'Onbekend',
        boss = boss, grades = gradeList(society), balance = account and account.balance or 0,
        accountNumber = account and account.account_number or society.account,
        employees = boss and employees or {}, history = history or {}
    })
end

local function validateAmount(src, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount < 1 or amount > Config.MaxTransactionAmount then
        notify(src, 'Ongeldig bedrag.')
        return nil
    end
    return amount
end

local function companyForBoss(src)
    local row, society = getPlayerSociety(src)
    if not row or not society or not isBoss(row, society) then
        notify(src, 'Je hebt geen toegang tot het bedrijfsbeheer.')
        return nil
    end
    return row, society
end

RegisterNetEvent('thootje-society:server:open', function() openFor(source) end)
RegisterNetEvent('thootje-society:server:refresh', function() updateClient(source) end)

RegisterNetEvent('thootje-society:server:deposit', function(rawAmount, desc)
    local src = source
    local row = getPlayerSociety(src)
    if not row then return notify(src, 'Je bent niet in dienst bij een bedrijf.') end
    local amount = validateAmount(src, rawAmount); if not amount then return end
    local ok, err = bankCall(Config.Banking.RemoveBankMoneyExport, src, amount)
    if not ok then return notify(src, err) end
    local changed = MySQL.update.await('UPDATE thootje_society_accounts SET balance = balance + ? WHERE society = ?', { amount, row.society })
    if changed ~= 1 then
        bankCall(Config.Banking.AddBankMoneyExport, src, amount)
        return notify(src, 'Bedrijfsrekening niet gevonden; bedrag teruggestort indien mogelijk.')
    end
    local account = getAccount(row.society)
    logTransaction(row.society, src, 'storting', amount, tostring(desc):sub(1, 255), account.balance)
    notify(src, ('€%s gestort op de bedrijfsrekening.'):format(amount)); updateClient(src)
end)

RegisterNetEvent('thootje-society:server:withdraw', function(rawAmount, desc)
    local src = source
    local row, society = companyForBoss(src); if not row then return end
    local amount = validateAmount(src, rawAmount); if not amount then return end
    local changed = MySQL.update.await('UPDATE thootje_society_accounts SET balance = balance - ? WHERE society = ? AND balance >= ?', { amount, row.society, amount })
    if changed ~= 1 then return notify(src, 'Onvoldoende saldo op de bedrijfsrekening.') end
    local ok, err = bankCall(Config.Banking.AddBankMoneyExport, src, amount)
    if not ok then
        MySQL.update.await('UPDATE thootje_society_accounts SET balance = balance + ? WHERE society = ?', { amount, row.society })
        return notify(src, err)
    end
    local account = getAccount(row.society)
    logTransaction(row.society, src, 'opname', amount, tostring(desc):sub(1, 255), account.balance)
    notify(src, ('€%s opgenomen van de bedrijfsrekening.'):format(amount)); updateClient(src)
end)

RegisterNetEvent('thootje-society:server:transfer', function(targetAccount, rawAmount, desc)
    local src = source
    local row, society = companyForBoss(src); if not row then return end
    local amount = validateAmount(src, rawAmount); if not amount then return end
    targetAccount = targetAccount:upper():gsub('%s+', '')
    local target = MySQL.single.await('SELECT society FROM thootje_society_accounts WHERE account_number = ?', { targetAccount })
    if not target then return notify(src, 'Doelrekening niet gevonden.') end
    if target.society == row.society then return notify(src, 'Je kunt niet naar dezelfde rekening overboeken.') end
    local affected = MySQL.update.await('UPDATE thootje_society_accounts SET balance = balance - ? WHERE society = ? AND balance >= ?', { amount, row.society, amount })
    if affected ~= 1 then return notify(src, 'Onvoldoende saldo op de bedrijfsrekening.') end
    MySQL.update.await('UPDATE thootje_society_accounts SET balance = balance + ? WHERE society = ?', { amount, target.society })
    local fromAcc, toAcc = getAccount(row.society), getAccount(target.society)
    logTransaction(row.society, src, 'overboeking', amount, ('Naar %s: %s'):format(targetAccount, tostring(desc):sub(1, 180)), fromAcc.balance)
    logTransaction(target.society, src, 'ontvangen', amount, ('Van %s: %s'):format(fromAcc.account_number, tostring(desc):sub(1, 180)), toAcc.balance)
    notify(src, 'Overboeking succesvol.'); updateClient(src)
end)

RegisterNetEvent('thootje-society:server:hire', function(targetId, grade)
    local src = source
    local row, society = companyForBoss(src); if not row then return end
    targetId, grade = tonumber(targetId), tonumber(grade) or 0
    if not targetId or not GetPlayerName(targetId) then return notify(src, 'Speler niet online.') end
    if targetId == src then return notify(src, 'Je kunt jezelf niet aannemen.') end
    if not society.grades[grade] or society.bossGrades[grade] then return notify(src, 'Ongeldige rang.') end
    local count = MySQL.scalar.await('SELECT COUNT(*) FROM thootje_society_employees WHERE society = ?', { row.society }) or 0
    if count >= Config.MaxEmployees then return notify(src, 'Het bedrijf heeft het maximale aantal medewerkers bereikt.') end
    local targetIdentifier = identifier(targetId)
    if not targetIdentifier then return notify(src, 'Speler-ID kon niet worden opgehaald.') end
    local existing = MySQL.single.await('SELECT society FROM thootje_society_employees WHERE identifier = ?', { targetIdentifier })
    if existing then return notify(src, 'Deze speler heeft al een baan. Ontsla hem eerst.') end
    MySQL.insert.await('INSERT INTO thootje_society_employees (society, identifier, player_name, grade, salary) VALUES (?, ?, ?, ?, 0)', { row.society, targetIdentifier, playerName(targetId), grade })
    notify(src, playerName(targetId) .. ' is aangenomen.'); notify(targetId, 'Je bent aangenomen bij ' .. society.label .. '!')
    updateClient(src)
end)

RegisterNetEvent('thootje-society:server:setGrade', function(employeeId, grade)
    local src = source
    local row, society = companyForBoss(src); if not row then return end
    employeeId, grade = tonumber(employeeId), tonumber(grade)
    if not employeeId or not society.grades[grade] then return notify(src, 'Ongeldige medewerker of rang.') end
    local employee = MySQL.single.await('SELECT * FROM thootje_society_employees WHERE id = ? AND society = ?', { employeeId, row.society })
    if not employee then return notify(src, 'Medewerker niet gevonden.') end
    if employee.identifier == identifier(src) then return notify(src, 'Je kunt je eigen rang niet aanpassen.') end
    if society.bossGrades[grade] and not society.bossGrades[tonumber(row.grade)] then return notify(src, 'Je kunt geen eigenaar/directierang toekennen.') end
    MySQL.update.await('UPDATE thootje_society_employees SET grade = ? WHERE id = ?', { grade, employeeId })
    notify(src, 'Rang aangepast.'); updateClient(src)
    for _, id in ipairs(GetPlayers()) do
        if identifier(tonumber(id)) == employee.identifier then notify(tonumber(id), 'Je nieuwe rang: ' .. society.grades[grade]); break end
    end
end)

RegisterNetEvent('thootje-society:server:fire', function(employeeId)
    local src = source
    local row = companyForBoss(src); if not row then return end
    employeeId = tonumber(employeeId)
    local employee = employeeId and MySQL.single.await('SELECT * FROM thootje_society_employees WHERE id = ? AND society = ?', { employeeId, row.society })
    if not employee then return notify(src, 'Medewerker niet gevonden.') end
    if employee.identifier == identifier(src) then return notify(src, 'Je kunt jezelf niet ontslaan.') end
    MySQL.query.await('DELETE FROM thootje_society_employees WHERE id = ?', { employeeId })
    notify(src, employee.player_name .. ' is ontslagen.'); updateClient(src)
    for _, id in ipairs(GetPlayers()) do
        if identifier(tonumber(id)) == employee.identifier then notify(tonumber(id), 'Je bent ontslagen.'); break end
    end
end)

RegisterCommand('societysetjob', function(src, args)
    if src ~= 0 and not IsPlayerAceAllowed(src, Config.AdminAce) then return notify(src, 'Geen toestemming.') end
    local target, societyName, grade = tonumber(args[1]), args[2], tonumber(args[3]) or 0
    local society = Societies[societyName]
    if not target or not society or not society.grades[grade] then
        if src == 0 then print('Gebruik: societysetjob [id] [bedrijf] [rang]') else notify(src, 'Gebruik: /societysetjob [id] [bedrijf] [rang]') end
        return
    end
    local id = identifier(target)
    if not id then return end
    MySQL.insert.await('INSERT INTO thootje_society_employees (society, identifier, player_name, grade, salary) VALUES (?, ?, ?, ?, 0) ON DUPLICATE KEY UPDATE society = VALUES(society), player_name = VALUES(player_name), grade = VALUES(grade)', { societyName, id, playerName(target), grade })
    notify(target, 'Je baan is ingesteld: ' .. society.label)
    if src ~= 0 then notify(src, 'Baan ingesteld.') end
end, false)

RegisterCommand('societyfire', function(src, args)
    if src ~= 0 and not IsPlayerAceAllowed(src, Config.AdminAce) then return notify(src, 'Geen toestemming.') end
    local target = tonumber(args[1])
    if not target then return end
    local id = identifier(target)
    if id then MySQL.query.await('DELETE FROM thootje_society_employees WHERE identifier = ?', { id }); notify(target, 'Je bent uit dienst gezet.') end
end, false)

exports('GetSocietyAccount', function(societyName)
    local acc = MySQL.single.await('SELECT * FROM thootje_society_accounts WHERE society = ?', { societyName })
    return acc
end)

exports('AddSocietyMoney', function(societyName, amount, reason)
    amount = math.floor(tonumber(amount) or 0)
    if amount < 1 or not Societies[societyName] then return false end
    MySQL.update.await('UPDATE thootje_society_accounts SET balance = balance + ? WHERE society = ?', { amount, societyName })
    local acc = getAccount(societyName)
    MySQL.insert.await('INSERT INTO thootje_society_transactions (society, actor_identifier, actor_name, transaction_type, amount, description, balance_after) VALUES (?, ?, ?, ?, ?, ?, ?)', { societyName, 'system', 'Systeem', 'inkomsten', amount, tostring(reason or 'Bedrijfsinkomsten'), acc.balance })
    return true
end)

exports('RemoveSocietyMoney', function(societyName, amount, reason)
    amount = math.floor(tonumber(amount) or 0)
    if amount < 1 or not Societies[societyName] then return false end
    local changed = MySQL.update.await('UPDATE thootje_society_accounts SET balance = balance - ? WHERE society = ? AND balance >= ?', { amount, societyName, amount })
    if changed ~= 1 then return false end
    local acc = getAccount(societyName)
    MySQL.insert.await('INSERT INTO thootje_society_transactions (society, actor_identifier, actor_name, transaction_type, amount, description, balance_after) VALUES (?, ?, ?, ?, ?, ?, ?)', { societyName, 'system', 'Systeem', 'uitgaven', amount, tostring(reason or 'Bedrijfskosten'), acc.balance })
    return true
end)

exports('GetEmployeeSociety', function(src)
    local row, society = getPlayerSociety(src)
    if not row then return nil end
    return { name = row.society, label = society.label, grade = row.grade, gradeLabel = society.grades[tonumber(row.grade)], boss = isBoss(row, society) }
end)

CreateThread(function()
    Wait(1000)
    ensureAccounts()
    if Config.PayrollEnabled then
        while true do
            Wait(Config.PayrollIntervalMinutes * 60000)
            local employees = MySQL.query.await('SELECT * FROM thootje_society_employees WHERE salary > 0')
            for _, employee in ipairs(employees or {}) do
                local online
                for _, id in ipairs(GetPlayers()) do
                    if identifier(tonumber(id)) == employee.identifier then online = tonumber(id); break end
                end
                if online then
                    local salary = math.floor(tonumber(employee.salary) or 0)
                    local charged = MySQL.update.await(
                        'UPDATE thootje_society_accounts SET balance = balance - ? WHERE society = ? AND balance >= ?',
                        { salary, employee.society, salary }
                    )
                    if charged == 1 then
                        local ok = bankCall(Config.Banking.AddBankMoneyExport, online, salary)
                        if not ok then
                            MySQL.update.await('UPDATE thootje_society_accounts SET balance = balance + ? WHERE society = ?', { salary, employee.society })
                        else
                            local acc = getAccount(employee.society)
                            logTransaction(employee.society, online, 'salaris', salary, 'Salarisbetaling', acc.balance)
                        end
                    end
                end
            end
        end
    end
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then print('^2[thootje-society] geladen. Importeer eerst sql/thootje_society.sql.^0') end
end)
