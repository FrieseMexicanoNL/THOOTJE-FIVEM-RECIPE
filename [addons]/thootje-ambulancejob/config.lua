Config = {}

Config.Debug = false
Config.JobName = 'ambulance'
Config.JobLabel = 'Ambulancedienst'
Config.OpenCommand = 'ems'
Config.DutyCommand = 'emsduty'
Config.CallCommand = '112'
Config.Key = 'F7'

Config.RequireDuty = true
Config.NotifyEvent = 'thootje-ambulancejob:client:notify'

-- Rangvereisten uit thootje-jobs (ambulance grades 0 t/m 5).
Config.Permissions = {
    tablet = 0,
    calls = 0,
    treatment = 0,
    revive = 1,
    invoice = 1,
    garage = 0,
    manage = 5
}

Config.Security = {
    ActionCooldownMs = 900,
    MaxCallText = 240,
    MaxTreatmentDistance = 4.0,
    MaxInvoiceDistance = 5.0,
    MaxInvoiceAmount = 25000,
    MinInvoiceAmount = 1,
    MaxCallDistanceFromMap = 12000.0,
    MaxActionsPerMinute = 35
}

Config.MedicalItems = {
    revive = { item = 'medikit', count = 1, label = 'Medikit' },
    heal = { item = 'bandage', count = 1, label = 'Verband' },
    stabilize = { item = 'firstaidkit', count = 1, label = 'EHBO-set' }
}

Config.Treatment = {
    reviveHealth = 150,
    healAmount = 45,
    stabilizeHealth = 110,
    reviveAnimationMs = 8000
}

Config.CallTypes = {
    { id = 'medical', label = 'Medische noodsituatie', icon = '✚' },
    { id = 'traffic', label = 'Verkeersongeval', icon = '🚑' },
    { id = 'fire', label = 'Brand / rook', icon = '🔥' },
    { id = 'other', label = 'Overige melding', icon = '!' }
}

Config.Vehicles = {
    { label = 'Ambulance', model = 'ambulance', minGrade = 0 },
    { label = 'Rapid Responder SUV', model = 'granger', minGrade = 2 },
    { label = 'Commandovoertuig', model = 'landstalker', minGrade = 4 }
}

Config.Stations = {
    {
        label = 'Pillbox Medical Center',
        coords = vector3(298.6, -584.2, 43.3),
        duty = vector3(306.8, -597.0, 43.3),
        garage = vector3(294.2, -574.1, 43.2),
        spawn = vector4(289.2, -574.0, 43.2, 70.0)
    },
    {
        label = 'Sandy Shores Medical',
        coords = vector3(1839.6, 3672.9, 34.3),
        duty = vector3(1833.5, 3673.9, 34.3),
        garage = vector3(1827.2, 3675.0, 34.3),
        spawn = vector4(1823.8, 3674.5, 34.3, 210.0)
    },
    {
        label = 'Paleto Medical',
        coords = vector3(-247.8, 6331.2, 32.4),
        duty = vector3(-254.2, 6336.8, 32.4),
        garage = vector3(-262.1, 6334.5, 32.4),
        spawn = vector4(-267.2, 6334.1, 32.4, 225.0)
    }
}

Config.Blips = {
    enabled = true,
    sprite = 61,
    color = 2,
    scale = 0.78,
    label = 'Ambulancedienst'
}

Config.Locale = {
    noJob = 'Je werkt niet bij de ambulancedienst.',
    offDuty = 'Je moet eerst in dienst zijn.',
    tooFar = 'De patiënt is te ver weg.',
    noTarget = 'Geen patiënt in de buurt gevonden.',
    noItem = 'Je hebt niet de benodigde medische benodigdheden.',
    invalid = 'Ongeldige gegevens.',
    noCall = 'Deze melding is niet meer beschikbaar.',
    assigned = 'De melding is aan jouw eenheid toegewezen.',
    completed = 'Melding succesvol afgerond.',
    treated = 'Behandeling uitgevoerd.'
}
