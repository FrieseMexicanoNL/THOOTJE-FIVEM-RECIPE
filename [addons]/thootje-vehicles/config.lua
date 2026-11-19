Config = {}

Config.CoreResource = 'thootje-core'
Config.GarageResource = 'thootje-garage'

Config.Identifier = function(src)
    local ok, data = pcall(function()
        return exports[Config.CoreResource]:GetPlayerData(src)
    end)
    if ok and type(data) == 'table' then
        local id = data.citizenid or data.charid or data.characterId or data.identifier
        if id and tostring(id) ~= '' then return tostring(id) end
    end
    for _, value in ipairs(GetPlayerIdentifiers(src)) do
        if value:sub(1, 8) == 'license:' then return value end
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

Config.OpenCommand = 'vehiclekeys'
Config.LockCommand = 'vehiclelock'
Config.OpenKey = 'F7'
Config.LockKey = 'U'
Config.ShareDistance = 3.0
Config.VehicleDistance = 8.0
Config.LockDistance = 12.0
Config.LockCooldownMs = 1200
Config.MaxSharedKeysPerVehicle = 8
Config.AllowPassengersToLock = true
Config.LockSound = true
Config.LockFlash = true
Config.RequireOwnedVehicle = true

Config.AdminAce = 'thootje.vehicles.admin'
Config.AdminGiveKeyCommand = 'givevehiclekey'

Config.LockStates = {
    locked = 2,
    unlocked = 1
}

Config.Notifications = {
    event = 'thootje-core:client:notify',
    type = 'info'
}

-- Indien jouw THOOTJE-CORE een andere identifier/API gebruikt,
-- pas Config.Identifier hierboven aan zodat deze overeenkomt met thootje-garage.
