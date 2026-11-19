Config = {}

Config.Debug = false
Config.OpenCommand = 'hud'
Config.OpenKey = 'F7'
Config.SaveInterval = 15000

-- Core-koppeling. Pas de eventnamen aan wanneer jouw thootje-core andere events gebruikt.
Config.Core = {
    Resource = 'thootje-core',
    PlayerLoadedEvent = 'thootje:client:playerLoaded',
    PlayerDataEvent = 'thootje:client:updateData',
    GetPlayerDataExport = 'GetPlayerData'
}

-- Gebruik deze events vanuit je needs-script om waarden live door te geven:
-- TriggerEvent('thootje-hud:client:setNeeds', hunger, thirst)
Config.DefaultNeeds = { hunger = 100, thirst = 100 }

Config.Modules = {
    health = true,
    armor = true,
    hunger = true,
    thirst = true,
    stamina = true,
    oxygen = true,
    voice = true,
    street = true,
    compass = true,
    time = true,
    player = true,
    job = true,
    cash = true,
    bank = true,
    vehicle = true,
    vehicleStreet = true
}

Config.Colors = {
    cyan = '#35e0d0',
    purple = '#a78bfa',
    orange = '#ffb454',
    red = '#ff647c',
    blue = '#60a5fa',
    lime = '#a3e635'
}
