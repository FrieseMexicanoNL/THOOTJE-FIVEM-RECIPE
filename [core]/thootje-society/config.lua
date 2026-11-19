Config = {}

Config.CoreResource = 'thootje-core'
Config.BankingResource = 'thootje-banking'
Config.Command = 'society'
Config.BossKey = 'F7'
Config.OpenDistance = 3.0
Config.InteractionMarker = true

-- Pas dit aan op de exports/events van jouw THOOTJE-CORE build.
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
        local name = data.name or data.charname or data.fullname
        if name then return tostring(name) end
    end
    return GetPlayerName(src) or ('Speler ' .. tostring(src))
end

-- Geld wordt primair via thootje-banking verwerkt. Zet fallback event naar jouw core
-- wanneer je banking-resource deze export niet aanbiedt.
Config.Banking = {
    AddBankMoneyExport = 'AddBankMoney',
    RemoveBankMoneyExport = 'RemoveBankMoney',
    GetBankMoneyExport = 'GetBankMoney',
    FallbackAddEvent = 'thootje-core:server:addBankMoney'
}

Config.AdminAce = 'thootje.society.admin'
Config.MaxEmployees = 50
Config.MaxTransactionAmount = 10000000
Config.TransactionHistory = 50
Config.PayrollIntervalMinutes = 60
Config.PayrollEnabled = true
Config.PayrollOnlyOnDuty = false

Config.Blip = { enabled = true, sprite = 475, color = 3, scale = 0.75 }
