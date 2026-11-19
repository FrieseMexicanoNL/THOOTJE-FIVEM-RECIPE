Config = {}

Config.CoreResource = 'thootje-core'
Config.BankingResource = 'thootje-banking'

-- Pas deze twee functies aan wanneer jouw THOOTJE-CORE andere velden gebruikt.
Config.Identifier = function(src)
    local ok, data = pcall(function()
        return exports[Config.CoreResource]:GetPlayerData(src)
    end)
    if ok and type(data) == 'table' then
        local id = data.citizenid or data.charid or data.characterId or data.identifier
        if id and tostring(id) ~= '' then return tostring(id) end
    end
    for _, identifier in ipairs(GetPlayerIdentifiers(src)) do
        if identifier:sub(1, 8) == 'license:' then return identifier end
    end
    return nil
end

Config.PlayerName = function(src)
    local ok, data = pcall(function()
        return exports[Config.CoreResource]:GetPlayerData(src)
    end)
    if ok and type(data) == 'table' then
        return tostring(data.name or data.charname or data.fullname or GetPlayerName(src) or 'Onbekend')
    end
    return GetPlayerName(src) or 'Onbekend'
end

Config.Command = 'garage'
Config.Key = 'F6'
Config.InteractDistance = 3.0
Config.OpenDistance = 12.0
Config.SpawnClearRadius = 3.0
Config.MaxVehiclesPerPlayer = 20
Config.AdminAce = 'thootje.garage.admin'

Config.VehicleDefaults = {
    fuel = 100.0,
    engine = 1000.0,
    body = 1000.0
}

Config.Impound = {
    enabled = true,
    fee = 750,
    bankExport = 'RemoveBankMoney',
    allowJobRelease = false
}

Config.Blips = {
    garage = { enabled = true, sprite = 357, color = 3, scale = 0.72, label = 'Garage' },
    impound = { enabled = true, sprite = 68, color = 47, scale = 0.72, label = 'Inbeslagname' }
}

Config.VehicleClassLabels = {
    [0]='Compact', [1]='Sedan', [2]='SUV', [3]='Coupé', [4]='Muscle',
    [5]='Sport classic', [6]='Sport', [7]='Super', [8]='Motor', [9]='Offroad',
    [10]='Industrieel', [11]='Utility', [12]='Van', [13]='Fiets',
    [14]='Boot', [15]='Helikopter', [16]='Vliegtuig', [17]='Dienstvoertuig',
    [18]='Hulpdienst', [19]='Leger', [20]='Bedrijfsvoertuig', [21]='Trein'
}
