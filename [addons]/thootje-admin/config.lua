Config = {}

Config.OpenCommand = 'admin'
Config.OpenKey = 'F10'
Config.AdminAce = 'thootje.admin'
Config.SuperAdminAce = 'thootje.admin.super'
Config.NotifyEvent = 'thootje-core:client:notify' -- pas aan indien nodig
Config.RefreshInterval = 15000
Config.MaxBanDays = 3650
Config.DefaultBanDays = 7
Config.AnnouncementPrefix = 'THOOTJE STAFF'
Config.LogActions = true

-- ACE permissions:
-- add_ace group.admin thootje.admin allow
-- add_ace group.admin thootje.admin.super allow
-- add_ace group.admin command allow

Config.Actions = {
    kick = true, warn = true, ban = true, unban = true,
    freeze = true, heal = true, revive = true,
    goto = true, bring = true, return = true,
    spectate = true, setweather = true, settime = true,
    announce = true, cleararea = true, spawnvehicle = true,
    restartresource = true
}
