THOOTJE_PCH = {}

function THOOTJE_PCH.GetPlayer(src)
    local ok, data = pcall(function() return exports['thootje-core']:GetPlayerData(src) end)
    if ok and data then return data end
    return nil
end

function THOOTJE_PCH.Identifier(src)
    local p = THOOTJE_PCH.GetPlayer(src)
    if p then return p.citizenid or p.charid or p.identifier or p.license end
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if id:find('license:') == 1 then return id end
    end
    return nil
end

function THOOTJE_PCH.Job(src)
    local ok, job = pcall(function() return exports['thootje-jobs']:GetJob(src) end)
    if ok and job then return job.name or job.job, tonumber(job.grade) or 0, job.duty == true end
    local state = Player(src) and Player(src).state.thootjeJob
    if state then return state.name, tonumber(state.grade) or 0, state.duty == true end
    return nil, 0, false
end

function THOOTJE_PCH.IsStaff(src)
    local name, grade, duty = THOOTJE_PCH.Job(src)
    return name == Config.JobName and (not Config.RequireDutyForActions or duty), grade, duty
end

function THOOTJE_PCH.Notify(src, msg, typ)
    TriggerClientEvent('ox_lib:notify', src, { title='THOOTJE Pechhulp', description=msg, type=typ or 'inform' })
end

function THOOTJE_PCH.HasItem(src, item, amount)
    local ok, result = pcall(function() return exports['thootje-inventory']:HasItem(src,item,amount or 1) end)
    return ok and result == true
end
function THOOTJE_PCH.RemoveItem(src,item,amount)
    local ok, result = pcall(function() return exports['thootje-inventory']:RemoveItem(src,item,amount or 1) end)
    return ok and result ~= false
end
function THOOTJE_PCH.AddItem(src,item,amount)
    local ok, result = pcall(function() return exports['thootje-inventory']:AddItem(src,item,amount or 1) end)
    return ok and result ~= false
end
