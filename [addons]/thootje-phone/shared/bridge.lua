THPhone = {}

function THPhone.GetIdentifier(src)
    if Config.Identifier ~= 'auto' then
        return GetPlayerIdentifierByType(src, Config.Identifier) or GetPlayerIdentifier(src, 0)
    end

    -- Pas dit aan wanneer jouw THOOTJE-CORE een andere character-ID export gebruikt.
    local ok, data = pcall(function()
        return exports[Config.CoreResource]:GetPlayerData(src)
    end)

    if ok and type(data) == 'table' then
        local identifier = data.citizenid or data.identifier or data.charid
        if identifier then return tostring(identifier) end
    end

    return GetPlayerIdentifierByType(src, 'license') or GetPlayerIdentifier(src, 0)
end

function THPhone.GetName(src)
    return GetPlayerName(src) or ('Speler %s'):format(src)
end
