THOOTJE_DRUGS = THOOTJE_DRUGS or {}

local function safeExport(resource, exportName, ...)
    if GetResourceState(resource) ~= 'started' then return false, 'resource_not_started' end
    local ok, a, b = pcall(function()
        return exports[resource][exportName](exports[resource], ...)
    end)
    if not ok then return false, a end
    return true, a, b
end

function THOOTJE_DRUGS.GetIdentifier(src)
    local ok, data = safeExport('thootje-core', 'GetPlayerData', src)
    if ok and type(data) == 'table' then
        return data.citizenid or data.charid or data.identifier or data.license
    end
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if id:sub(1, 8) == 'license:' then return id end
    end
    return nil
end

function THOOTJE_DRUGS.GetJob(src)
    local ok, job = safeExport('thootje-jobs', 'GetJob', src)
    if ok and type(job) == 'table' then
        return job.name or job.job or job.label, job.grade or 0, job.duty == true or job.onduty == true
    end
    local state = Player(src).state.thootjeJob
    if type(state) == 'table' then
        return state.name or state.job, state.grade or 0, state.duty == true or state.onduty == true
    end
    return nil, 0, false
end

function THOOTJE_DRUGS.HasItem(src, item, amount)
    local ok, result = safeExport(Config.Inventory.Resource, Config.Inventory.HasExport, src, item, amount)
    if ok then return result == true end
    local ok2, inv = safeExport(Config.Inventory.Resource, Config.Inventory.GetExport, src)
    if ok2 and type(inv) == 'table' then
        for _, entry in pairs(inv.items or inv) do
            if type(entry) == 'table' and (entry.name == item or entry.item == item) then
                return (tonumber(entry.count or entry.amount) or 0) >= amount
            end
        end
    end
    return false
end

function THOOTJE_DRUGS.AddItem(src, item, amount)
    local ok, result = safeExport(Config.Inventory.Resource, Config.Inventory.AddExport, src, item, amount)
    return ok and result ~= false
end

function THOOTJE_DRUGS.RemoveItem(src, item, amount)
    local ok, result = safeExport(Config.Inventory.Resource, Config.Inventory.RemoveExport, src, item, amount)
    return ok and result ~= false
end

function THOOTJE_DRUGS.Notify(src, message, kind)
    TriggerClientEvent('thootje-drugs:client:notify', src, message, kind or 'inform')
end

function THOOTJE_DRUGS.IsPolice(src)
    local job, _, duty = THOOTJE_DRUGS.GetJob(src)
    return job == Config.Police.JobName and duty
end
