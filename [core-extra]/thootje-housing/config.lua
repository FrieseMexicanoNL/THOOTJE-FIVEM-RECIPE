Config = {}

Config.CoreResource = 'thootje-core'
Config.Identifier = 'auto' -- auto: probeer character identifier uit core, anders license:
Config.NotifyEvent = 'thootje-core:client:notify'
Config.AdminAce = 'thootje.housing.admin'

Config.OpenCommand = 'huizen'
Config.ExitCommand = 'huisverlaten'
Config.KeyCommand = 'huissleutel'
Config.InteractDistance = 2.0
Config.DrawDistance = 15.0
Config.PaymentAccount = 'bank' -- bank of cash; pas bridge aan op jouw core
Config.DefaultRentDays = 7
Config.RentCheckMinutes = 30
Config.BuyEnabled = true
Config.RentEnabled = true
Config.AllowOwnerSell = true
Config.MaxKeysPerProperty = 5
Config.PropertyBlip = {
    enabled = true,
    sprite = 40,
    color = 3,
    scale = 0.65,
    label = 'Beschikbaar vastgoed'
}

-- Interieurs zijn voorbeeldcoördinaten. Vervang deze door jouw MLO/shell-interieurs.
-- Elke woning krijgt een eigen routing bucket zodat spelers elkaar niet zien.
Config.Interiors = {
    apartment = {
        label = 'Appartement interieur',
        entry = vector4(266.05, -1007.45, -101.01, 357.0),
        exit = vector4(266.05, -1007.45, -101.01, 357.0),
        stash = vector3(265.9, -999.4, -99.0)
    },
    house = {
        label = 'Standaard woning interieur',
        entry = vector4(346.52, -1012.85, -99.2, 0.0),
        exit = vector4(346.52, -1012.85, -99.2, 0.0),
        stash = vector3(351.9, -998.8, -99.2)
    }
}

-- Voeg hier je eigen huizen en appartementen toe.
-- type: apartment of house | price = koopprijs | rent = huurprijs per periode
Config.Properties = {
    {
        id = 'apt_vespucci_01',
        label = 'Vespucci Appartement 01',
        type = 'apartment',
        address = 'Vespucci Boulevard 1',
        exterior = vector4(-1150.2, -1520.5, 10.6, 125.0),
        price = 85000,
        rent = 2500,
        forSale = true,
        forRent = true
    },
    {
        id = 'house_mirror_01',
        label = 'Mirror Park Woning 01',
        type = 'house',
        address = 'Mirror Park 01',
        exterior = vector4(1260.2, -601.7, 68.1, 90.0),
        price = 175000,
        rent = 5000,
        forSale = true,
        forRent = true
    },
    {
        id = 'house_sandy_01',
        label = 'Sandy Shores Woning 01',
        type = 'house',
        address = 'Sandy Shores 01',
        exterior = vector4(1961.2, 3819.1, 33.4, 210.0),
        price = 95000,
        rent = 3000,
        forSale = true,
        forRent = true
    }
}

Config.Text = {
    no_money = 'Je hebt niet genoeg saldo.',
    bought = 'Je hebt de woning gekocht!',
    rented = 'Je hebt de woning gehuurd.',
    not_owner = 'Je bent geen eigenaar van deze woning.',
    no_access = 'Je hebt geen toegang tot deze woning.',
    already_owned = 'Deze woning is al in gebruik.',
    not_found = 'Woning niet gevonden.',
    keys_sent = 'Huissleutel succesvol gedeeld.',
    keys_removed = 'Huissleutel ingetrokken.',
    entered = 'Je bent de woning binnengegaan.',
    exited = 'Je hebt de woning verlaten.'
}
