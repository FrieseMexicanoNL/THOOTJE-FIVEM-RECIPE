local actionCounts, cooldowns = {}, {}

local function debugPrint(...) if Config.Debug then print('^3[thootje-jobs]^7', ...) end end
local function notify(src, msg, kind) TriggerClientEvent('thootje-jobs:client:notify', src, msg, kind or 'info') end

local function getIdentifier(src)
    if Config.IdentifierMode == 'license' then
        for _, v in ipairs(GetPlayerIdentifiers(src)) do if v:sub(1,8) == 'license:' then return v end end
    end
    local ok, data = pcall(function() return exports[Config.CoreResource]:GetPlayerData(src) end)
    if ok and type(data) == 'table' then
        local p = data.PlayerData or data.playerData or data
        for _, field in ipairs(Config.IdentifierFields) do
            if p[field] ~= nil and tostring(p[field]) ~= '' then return tostring(p[field]) end
        end
    end
    for _, v in ipairs(GetPlayerIdentifiers(src)) do if v:sub(1,8) == 'license:' then return v end end
    return nil
end

local function rateLimit(src)
    local now = os.time()
    actionCounts[src] = actionCounts[src] or { time = now, count = 0 }
    local row = actionCounts[src]
    if now - row.time >= 60 then row.time, row.count = now, 0 end
    row.count = row.count + 1
    return row.count > Config.Security.MaxActionsPerMinute
end

local function gradeInfo(jobName, grade)
    local job = Jobs[jobName]
    if not job then return nil end
    return job.grades[tonumber(grade) or 0]
end

local function ensurePlayer(src)
    local identifier = getIdentifier(src)
    if not identifier then return nil end
    local row = MySQL.single.await('SELECT * FROM thootje_jobs_players WHERE identifier = ?', { identifier })
    if not row then
        MySQL.insert.await('INSERT INTO thootje_jobs_players (identifier, job_name, grade, onduty) VALUES (?, ?, 0, 0)', { identifier, 'unemployed' })
        row = MySQL.single.await('SELECT * FROM thootje_jobs_players WHERE identifier = ?', { identifier })
    end
    if row and not Jobs[row.job_name] then
        row.job_name, row.grade, row.onduty = 'unemployed', 0, 0
        MySQL.update.await('UPDATE thootje_jobs_players SET job_name = ?, grade = 0, onduty = 0 WHERE identifier = ?', { 'unemployed', identifier })
    end
    return row, identifier
end

local function publicJobData(row)
    local job = Jobs[row.job_name] or Jobs.unemployed
    local grade = gradeInfo(row.job_name, row.grade) or gradeInfo('unemployed', 0)
    return {
        name = row.job_name, label = job.label, category = job.category,
        grade = tonumber(row.grade), gradeName = grade.name, gradeLabel = grade.label,
        salary = tonumber(grade.salary) or 0, onduty = tonumber(row.onduty) == 1,
        isBoss = grade.isBoss == true
    }
end

local function pushJob(src, row)
    local data = publicJobData(row)
    Player(src).state:set('thootjeJob', data, true)
    TriggerClientEvent('thootje-jobs:client:setJob', src, data)
    -- Optionele bridge: jouw core kan op dit event jobdata synchroniseren.
    TriggerEvent('thootje-jobs:server:jobUpdated', src, data)
end

local function getJobDataForUI(src)
    local row = ensurePlayer(src)
    if not row then return nil end
    local current = publicJobData(row)
    local available = {}
    for name, job in pairs(Jobs) do
        if job.public then
            local grades = {}
            for grade, info in pairs(job.grades) do
                grades[#grades+1] = { grade = tonumber(grade), label = info.label }
            end
            table.sort(grades, function(a,b) return a.grade < b.grade end)
            available[#available+1] = { name = name, label = job.label, category = job.category, description = job.description, grades = grades }
        end
    end
    table.sort(available, function(a,b) return a.label < b.label end)
    return { current = current, jobs = available, title = Config.UI.Title, subtitle = Config.UI.Subtitle }
end

RegisterNetEvent('thootje-jobs:server:requestData', function()
    local src = source
    if rateLimit(src) then return end
    local data = getJobDataForUI(src)
    if not data then return notify(src, 'Je personagegegevens konden niet worden geladen.', 'error') end
    TriggerClientEvent('thootje-jobs:client:openData', src, data)
end)

RegisterNetEvent('thootje-jobs:server:applyJob', function(jobName)
    local src = source
    if rateLimit(src) then return end
    jobName = tostring(jobName or '')
    local job = Jobs[jobName]
    if not job or not job.public then return notify(src, 'Voor deze functie kun je niet solliciteren via het vacaturecentrum.', 'error') end
    local now = os.time()
    if cooldowns[src] and now - cooldowns[src] < Config.Security.ChangeJobCooldownSeconds then return end
    cooldowns[src] = now
    local row, identifier = ensurePlayer(src)
    if not row then return end
    MySQL.update.await('UPDATE thootje_jobs_players SET job_name = ?, grade = 0, onduty = 0 WHERE identifier = ?', { jobName, identifier })
    local fresh = MySQL.single.await('SELECT * FROM thootje_jobs_players WHERE identifier = ?', { identifier })
    pushJob(src, fresh)
    notify(src, ('Je bent aangenomen bij %s als %s.'):format(job.label, job.grades[0].label), 'success')
    TriggerClientEvent('thootje-jobs:client:jobChanged', src)
end)

local function toggleDutyForPlayer(src)
    if not src or src <= 0 or rateLimit(src) then return end
    local row, identifier = ensurePlayer(src)
    if not row then return end
    local newDuty = tonumber(row.onduty) == 1 and 0 or 1
    if row.job_name == 'unemployed' then return notify(src, 'Je hebt geen werkgever waarbij je kunt inklokken.', 'error') end
    MySQL.update.await('UPDATE thootje_jobs_players SET onduty = ? WHERE identifier = ?', { newDuty, identifier })
    row.onduty = newDuty
    pushJob(src, row)
    notify(src, newDuty == 1 and 'Je bent nu ingeklokt.' or 'Je bent uitgeklokt.', 'success')
end

RegisterNetEvent('thootje-jobs:server:toggleDuty', function()
    toggleDutyForPlayer(source)
end)

RegisterCommand(Config.Commands.MyJob, function(src)
    if src == 0 then return end
    local row = ensurePlayer(src)
    if not row then return end
    local data = publicJobData(row)
    notify(src, ('%s | %s | %s'):format(data.label, data.gradeLabel, data.onduty and 'In dienst' or 'Uit dienst'), 'info')
end, false)

RegisterCommand(Config.Commands.Duty, function(src)
    if src == 0 then return end
    toggleDutyForPlayer(src)
end, false)

local function isAdmin(src)
    return src == 0 or IsPlayerAceAllowed(src, Config.AdminAce)
end

RegisterCommand(Config.Commands.SetJob, function(src, args)
    if not isAdmin(src) then return notify(src, 'Je hebt geen toestemming.', 'error') end
    local target, jobName, grade = tonumber(args[1]), tostring(args[2] or ''), tonumber(args[3]) or 0
    if not target or not GetPlayerName(target) or not Jobs[jobName] or not gradeInfo(jobName, grade) then
        if src ~= 0 then notify(src, 'Gebruik: /setjob [id] [job] [rang]', 'error') end
        return
    end
    local row, identifier = ensurePlayer(target)
    if not row then return end
    MySQL.update.await('UPDATE thootje_jobs_players SET job_name = ?, grade = ?, onduty = 0 WHERE identifier = ?', { jobName, grade, identifier })
    local fresh = MySQL.single.await('SELECT * FROM thootje_jobs_players WHERE identifier = ?', { identifier })
    pushJob(target, fresh)
    notify(target, ('Je functie is gewijzigd naar %s (%s).'):format(Jobs[jobName].label, gradeInfo(jobName, grade).label), 'success')
    if src ~= 0 then notify(src, 'Functie succesvol aangepast.', 'success') end
end, false)

RegisterCommand(Config.Commands.SetGrade, function(src, args)
    if not isAdmin(src) then return notify(src, 'Je hebt geen toestemming.', 'error') end
    local target, grade = tonumber(args[1]), tonumber(args[2])
    if not target or not GetPlayerName(target) or not grade then return end
    local row, identifier = ensurePlayer(target)
    if not row or not gradeInfo(row.job_name, grade) then return notify(src, 'Ongeldige rang voor deze baan.', 'error') end
    MySQL.update.await('UPDATE thootje_jobs_players SET grade = ? WHERE identifier = ?', { grade, identifier })
    row.grade = grade
    pushJob(target, row)
    notify(target, ('Je rang is gewijzigd naar %s.'):format(gradeInfo(row.job_name, grade).label), 'success')
    if src ~= 0 then notify(src, 'Rang succesvol aangepast.', 'success') end
end, false)

RegisterCommand(Config.Commands.Fire, function(src, args)
    if not isAdmin(src) then return notify(src, 'Je hebt geen toestemming.', 'error') end
    local target = tonumber(args[1])
    if not target or not GetPlayerName(target) then return end
    local row, identifier = ensurePlayer(target)
    if not row then return end
    MySQL.update.await('UPDATE thootje_jobs_players SET job_name = ?, grade = 0, onduty = 0 WHERE identifier = ?', { 'unemployed', identifier })
    local fresh = MySQL.single.await('SELECT * FROM thootje_jobs_players WHERE identifier = ?', { identifier })
    pushJob(target, fresh)
    notify(target, 'Je bent ontslagen en staat nu geregistreerd als werkloos.', 'error')
    if src ~= 0 then notify(src, 'Speler is ontslagen.', 'success') end
end, false)

exports('GetJob', function(src)
    local row = ensurePlayer(src)
    return row and publicJobData(row) or nil
end)

exports('SetJob', function(src, jobName, grade)
    grade = tonumber(grade) or 0
    if not Jobs[jobName] or not gradeInfo(jobName, grade) then return false end
    local row, identifier = ensurePlayer(src)
    if not row then return false end
    MySQL.update.await('UPDATE thootje_jobs_players SET job_name = ?, grade = ?, onduty = 0 WHERE identifier = ?', { jobName, grade, identifier })
    local fresh = MySQL.single.await('SELECT * FROM thootje_jobs_players WHERE identifier = ?', { identifier })
    pushJob(src, fresh)
    return true
end)

exports('SetDuty', function(src, state)
    local row, identifier = ensurePlayer(src)
    if not row then return false end
    local duty = state and 1 or 0
    MySQL.update.await('UPDATE thootje_jobs_players SET onduty = ? WHERE identifier = ?', { duty, identifier })
    row.onduty = duty
    pushJob(src, row)
    return true
end)

exports('GetPlayersByJob', function(jobName, onDutyOnly)
    local rows = MySQL.query.await('SELECT identifier, job_name, grade, onduty FROM thootje_jobs_players WHERE job_name = ?', { jobName }) or {}
    local result = {}
    for _, row in ipairs(rows) do
        if not onDutyOnly or tonumber(row.onduty) == 1 then result[#result+1] = row end
    end
    return result
end)

CreateThread(function()
    while true do
        Wait(Config.Paycheck.IntervalMinutes * 60000)
        if Config.Paycheck.Enabled then
            for _, player in ipairs(GetPlayers()) do
                local src = tonumber(player)
                local row = ensurePlayer(src)
                if row then
                    local grade = gradeInfo(row.job_name, row.grade)
                    local allowed = not Config.Paycheck.OnlyOnDuty or tonumber(row.onduty) == 1
                    local salary = grade and tonumber(grade.salary) or 0
                    if allowed and salary > 0 then
                        local paid = false
                        if Config.Paycheck.UseBankingResource and GetResourceState(Config.Paycheck.BankingResource) == 'started' then
                            paid = exports[Config.Paycheck.BankingResource]:AddBankMoney(src, salary, 'Salaris - ' .. (Jobs[row.job_name].label))
                        end
                        if not paid then
                            TriggerEvent(Config.Paycheck.FallbackCoreEvent, src, salary, 'Salaris')
                        end
                        notify(src, ('Salaris ontvangen: €%s.'):format(salary), 'success')
                    end
                end
            end
        end
    end
end)

AddEventHandler('playerDropped', function()
    actionCounts[source], cooldowns[source] = nil, nil
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    Wait(1000)
    for _, player in ipairs(GetPlayers()) do
        local src = tonumber(player)
        local row = ensurePlayer(src)
        if row then pushJob(src, row) end
    end
end)
