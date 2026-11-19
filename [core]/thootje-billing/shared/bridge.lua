THOOTJE_BILLING = {}

function THOOTJE_BILLING.GetIdentifier(src)
    local ok, data = pcall(function() return exports['thootje-core']:GetPlayerData(src) end)
    if ok and type(data)=='table' then
        return data.citizenid or data.charid or data.identifier or data.license
    end
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if id:sub(1,8)=='license:' then return id end
    end
    return nil
end

function THOOTJE_BILLING.GetCharacterName(src)
    local ok, data = pcall(function() return exports['thootje-core']:GetPlayerData(src) end)
    if ok and type(data)=='table' then
        if data.charinfo then
            local f=data.charinfo.firstname or ''
            local l=data.charinfo.lastname or ''
            if (f..l)~='' then return (f..' '..l):gsub('^%s*(.-)%s*$','%1') end
        end
        return data.name or data.fullname or GetPlayerName(src) or 'Onbekend'
    end
    return GetPlayerName(src) or 'Onbekend'
end

function THOOTJE_BILLING.Notify(src, msg, kind)
    TriggerClientEvent(Config.NotifyEvent, src, msg, kind or 'info')
end

local function bankCall(exportName, ...)
    local resource=Config.Banking.resource
    if GetResourceState(resource)~='started' then return false, 'banking resource not started' end
    local ok, result=pcall(function()
        return exports[resource][exportName](...)
    end)
    if not ok then return false, result end
    return true, result
end

function THOOTJE_BILLING.GetBalance(src)
    local ok, value=bankCall(Config.Banking.getBalanceExport, src)
    if not ok then return nil end
    return tonumber(value)
end

function THOOTJE_BILLING.RemoveBank(src, amount)
    local ok, result=bankCall(Config.Banking.removeExport, src, amount)
    return ok and result==true
end

function THOOTJE_BILLING.AddBank(src, amount)
    local ok, result=bankCall(Config.Banking.addExport, src, amount)
    return ok and result==true
end
