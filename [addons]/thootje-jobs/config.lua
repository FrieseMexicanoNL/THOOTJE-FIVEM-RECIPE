Config = {}

Config.CoreResource = 'thootje-core'
Config.IdentifierMode = 'character'
Config.IdentifierFields = { 'citizenid', 'charid', 'characterId', 'identifier', 'id' }

Config.Commands = {
    JobCenter = 'jobs',
    MyJob = 'myjob',
    Duty = 'dienst',
    SetJob = 'setjob',
    SetGrade = 'setgrade',
    Fire = 'firejob'
}

Config.Keybind = 'F6'
Config.JobCenter = {
    UseMarkers = true,
    DrawDistance = 18.0,
    InteractDistance = 2.0,
    Locations = {
        vector3(-265.12, -963.62, 31.22),
        vector3(441.18, -981.92, 30.69) -- tweede informatiepunt; verwijder als ongewenst
    }
}

Config.Paycheck = {
    Enabled = true,
    IntervalMinutes = 15,
    OnlyOnDuty = true,
    UseBankingResource = true,
    BankingResource = 'thootje-banking',
    FallbackCoreEvent = 'thootje-core:server:addBankMoney'
}

Config.Security = {
    MaxActionsPerMinute = 20,
    ChangeJobCooldownSeconds = 10,
    MaxGrade = 20
}

Config.UI = {
    Title = 'THOOTJE CAREERS',
    Subtitle = 'Vind jouw plek in de stad.',
    Accent = '#39dfc6'
}

-- ACE permission voor administratieve jobcommando's:
-- add_ace group.admin thootje.jobs.admin allow
Config.AdminAce = 'thootje.jobs.admin'
