Config = {}

Config.Debug = false
Config.OpenCommand = 'shops'
Config.InteractKey = 38 -- E
Config.DrawDistance = 18.0
Config.InteractDistance = 2.0
Config.UseTarget = false -- set true only after adding your target integration
Config.TargetResource = 'ox_target'

-- Default payment is an inventory cash item so this resource does not invent
-- an undocumented banking API. Change the item name to match your inventory.
Config.Currency = {
    item = 'money',
    label = 'Contant geld',
    symbol = '$'
}

Config.SellMultiplier = 1.0
Config.TransactionLog = true
Config.MaxTransactionAmount = 100
Config.RequireShopDistance = true

Config.Blips = {
    enabled = true,
    sprite = 52,
    color = 2,
    scale = 0.65
}

-- Item names must exist in thootje-inventory / your item definitions.
-- Each shop can have its own buy and sell list.
Config.Shops = {
    ['247_legion'] = {
        label = '24/7 Supermarkt',
        subtitle = 'Dagelijkse benodigdheden',
        type = 'shop',
        coords = vector3(25.7, -1347.3, 29.5),
        blip = true,
        buy = {
            { item = 'water', label = 'Waterfles', price = 15, category = 'Drinken', description = 'Een fles gekoeld water.' },
            { item = 'bread', label = 'Brood', price = 20, category = 'Eten', description = 'Vers brood voor onderweg.' },
            { item = 'sandwich', label = 'Broodje', price = 30, category = 'Eten', description = 'Een belegd broodje.' },
            { item = 'phone', label = 'Telefoon', price = 350, category = 'Elektronica', description = 'Een mobiele telefoon.' },
            { item = 'radio', label = 'Portofoon', price = 200, category = 'Elektronica', description = 'Communiceer met anderen.' }
        },
        sell = {
            { item = 'water', label = 'Waterfles', price = 5, category = 'Drinken' },
            { item = 'bread', label = 'Brood', price = 7, category = 'Eten' }
        }
    },
    ['hardware'] = {
        label = 'Bouwmarkt',
        subtitle = 'Gereedschap en materialen',
        type = 'shop',
        coords = vector3(2748.0, 3472.0, 55.7),
        blip = true,
        buy = {
            { item = 'repairkit', label = 'Reparatieset', price = 250, category = 'Gereedschap', description = 'Voor kleine reparaties.' },
            { item = 'bandage', label = 'Verband', price = 45, category = 'Medisch', description = 'Verzorg kleine verwondingen.' }
        },
        sell = {}
    },
    ['fishing_buyer'] = {
        label = 'Visinkoper',
        subtitle = 'Verkoop hier je gevangen vis',
        type = 'sell',
        coords = vector3(-1038.0, -1396.0, 5.55),
        blip = true,
        buy = {},
        sell = {
            { item = 'fish', label = 'Vis', price = 35, category = 'Vis' },
            { item = 'salmon', label = 'Zalm', price = 65, category = 'Vis' },
            { item = 'tuna', label = 'Tonijn', price = 90, category = 'Vis' }
        }
    },
    ['blackmarket'] = {
        label = 'Handelaar',
        subtitle = 'Een discreet verkooppunt',
        type = 'sell',
        coords = vector3(1391.0, 3605.0, 38.9),
        blip = false,
        buy = {},
        sell = {
            { item = 'stolen_goods', label = 'Gestolen goederen', price = 120, category = 'Goederen' }
        }
    }
}

Config.Locale = {
    tooFar = 'Je bent te ver van deze winkel.',
    noMoney = 'Je hebt niet genoeg contant geld.',
    noItem = 'Je hebt niet genoeg van dit item.',
    inventoryFull = 'Je inventory heeft niet genoeg ruimte.',
    bought = 'Aankoop geslaagd.',
    sold = 'Verkoop geslaagd.',
    invalid = 'Ongeldige transactie.',
    amount = 'Ongeldig aantal.'
}
