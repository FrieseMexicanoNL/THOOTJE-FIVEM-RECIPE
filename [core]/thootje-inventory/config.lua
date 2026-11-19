Config = {}

Config.Debug = false
Config.OpenCommand = 'inventory'
Config.OpenKey = 'TAB'
Config.MaxWeight = 30000 -- gram
Config.Slots = 30
Config.HotbarSlots = 5
Config.MaxGiveDistance = 3.0
Config.DropDistance = 2.0
Config.DropLifetimeHours = 24
Config.AllowDrop = true
Config.AllowGive = true
Config.AllowSplit = true

Config.Text = {
    title = 'THOOTJE INVENTORY',
    subtitle = 'Jouw spullen, jouw verhaal',
    empty = 'Deze plek is leeg',
    noPlayer = 'Er staat niemand dichtbij.',
    tooHeavy = 'Je inventory is te zwaar.',
    full = 'Je inventory heeft geen vrije plek.',
    invalid = 'Ongeldige actie of item.',
    used = 'Item gebruikt.',
    dropped = 'Item op de grond gelegd.',
    pickedUp = 'Item opgepakt.',
    received = 'Je hebt een item ontvangen.',
    given = 'Item overgedragen.'
}

-- Item definitions. Weights are in grams.
Config.Items = {
    water = {
        label = 'Flesje water', description = 'Een verfrissend flesje water.',
        weight = 500, image = 'water.png', type = 'item', stack = true,
        usable = true, close = true, rarity = 'common', effect = 'drink'
    },
    bread = {
        label = 'Broodje', description = 'Een vers broodje voor onderweg.',
        weight = 300, image = 'bread.png', type = 'item', stack = true,
        usable = true, close = true, rarity = 'common', effect = 'eat'
    },
    sandwich = {
        label = 'Belegd broodje', description = 'Een stevig belegd broodje.',
        weight = 450, image = 'sandwich.png', type = 'item', stack = true,
        usable = true, close = true, rarity = 'uncommon', effect = 'eat'
    },
    bandage = {
        label = 'Verband', description = 'Verzorg kleine verwondingen.',
        weight = 200, image = 'bandage.png', type = 'item', stack = true,
        usable = true, close = true, rarity = 'common', effect = 'heal'
    },
    phone = {
        label = 'Smartphone', description = 'Je persoonlijke telefoon.',
        weight = 250, image = 'phone.png', type = 'item', stack = false,
        usable = true, close = true, rarity = 'rare', effect = 'phone'
    },
    radio = {
        label = 'Portofoon', description = 'Communiceer met anderen.',
        weight = 800, image = 'radio.png', type = 'item', stack = false,
        usable = true, close = true, rarity = 'uncommon', effect = 'radio'
    },
    repairkit = {
        label = 'Reparatieset', description = 'Een set om voertuigen te repareren.',
        weight = 2500, image = 'repairkit.png', type = 'item', stack = true,
        usable = true, close = true, rarity = 'uncommon', effect = 'repairkit'
    },
    money = {
        label = 'Contant geld', description = 'Contant geld in je zak.',
        weight = 0, image = 'money.png', type = 'item', stack = true,
        usable = false, close = false, rarity = 'common'
    }
}

Config.Rarities = {
    common = 'Normaal',
    uncommon = 'Ongewoon',
    rare = 'Zeldzaam',
    epic = 'Episch',
    legendary = 'Legendarisch'
}

Config.UseEffects = {
    eat = { health = 5 },
    drink = { health = 2, armour = 2 },
    heal = { health = 25 },
}
