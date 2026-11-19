Config = {}

Config.Debug = false
Config.CoreResource = 'thootje-core'

Config.Commands = {
    Bank = 'bank',
    ATM = 'atm'
}

Config.Keybind = 'F6'
Config.AccountPrefix = 'TH'
Config.AccountNumberLength = 8
Config.DefaultAccountType = 'betaalrekening'
Config.Currency = 'EUR'
Config.CurrencySymbol = '€'
Config.MaxTransfer = 250000
Config.MinTransfer = 1
Config.TransferFee = 0
Config.MaxReasonLength = 60
Config.TransactionHistory = 30
Config.RequireNearbyBank = false
Config.BankLocations = {
    vector3(149.9, -1040.46, 29.37),
    vector3(-1212.98, -330.84, 37.79),
    vector3(-2962.58, 482.62, 15.70),
    vector3(-112.20, 6469.29, 31.63),
    vector3(314.19, -278.62, 54.17),
    vector3(-351.53, -49.53, 49.04)
}
Config.ATMModels = {
    `prop_atm_01`, `prop_atm_02`, `prop_atm_03`, `prop_fleeca_atm`
}

-- Identifier: bij voorkeur character-id uit jouw THOOTJE-CORE.
-- De resource probeert automatisch citizenid, charid, characterId of identifier
-- uit exports['thootje-core']:GetPlayerData(source) te lezen.
-- Stel dit in op 'license' als je bewust één rekening per FiveM-license wilt.
Config.IdentifierMode = 'character'
Config.IdentifierFields = { 'citizenid', 'charid', 'characterId', 'identifier', 'id' }

Config.Account = {
    Name = 'Mijn betaalrekening',
    InitialBalance = 0,
    AllowSelfTransfer = false
}

Config.Security = {
    TransferCooldownSeconds = 3,
    MaxRequestsPerMinute = 20
}

Config.UI = {
    Accent = '#39dfc6',
    BankName = 'THOOTJE BANK',
    Tagline = 'Jouw geld. Jouw controle.'
}
