Config = {}

Config.Debug = false
Config.Locale = 'nl'
Config.DefaultSpawn = vector4(-1037.7, -2737.8, 20.1, 329.0)

Config.StartingMoney = {
    cash = 500,
    bank = 2500,
    black_money = 0
}

Config.DefaultJob = {
    name = 'unemployed',
    label = 'Werkloos',
    grade = 0,
    gradeLabel = 'Burger'
}

Config.MaxInventoryWeight = 30000 -- gram
Config.InventorySlots = 30

Config.AdminGroups = {
    owner = true,
    admin = true
}

Config.Items = {
    water = { label = 'Water', weight = 500, stack = true, usable = true },
    bread = { label = 'Brood', weight = 300, stack = true, usable = true },
    phone = { label = 'Telefoon', weight = 250, stack = false, usable = true },
    bandage = { label = 'Verband', weight = 200, stack = true, usable = true }
}

Config.Commands = {
    cash = 'cash',
    inventory = 'inv',
    giveItem = 'giveitem',
    setJob = 'setjob',
    setMoney = 'setmoney'
}
