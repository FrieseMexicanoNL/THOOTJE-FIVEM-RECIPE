Config = {}

Config.Debug = false
Config.Locale = 'nl'
Config.InteractKey = 38 -- E
Config.InteractDistance = 2.0
Config.DrawDistance = 18.0
Config.MarkerType = 2
Config.MarkerScale = vec3(0.28, 0.28, 0.22)
Config.RequireOnFoot = true

-- Zet op true om alleen spelers met een geldig character-ID toe te staan.
Config.RequireCharacter = true

-- Inventarisadapter. Pas deze exports aan als jouw thootje-inventory andere namen gebruikt.
Config.Inventory = {
    Resource = 'thootje-inventory',
    AddExport = 'AddItem',
    RemoveExport = 'RemoveItem',
    HasExport = 'HasItem',
    GetExport = 'GetInventory',
    UseExportFallback = true
}

-- Politie-integratie: stuurt een dispatch-event naar thootje-politiejob.
Config.Police = {
    Enabled = true,
    JobName = 'police',
    MinimumOnDuty = 1,
    Chance = 72, -- percentage kans op melding bij NPC-verkoop
    CooldownSeconds = 90,
    Event = 'thootje-politiejob:server:drugAlert',
    BlipDuration = 90,
    DispatchTitle = 'Mogelijke drugsdeal',
    DispatchCode = '10-31',
    DispatchDescription = 'Melding van een mogelijke drugsdeal',
    Jobs = { 'police' }
}

Config.Selling = {
    Enabled = true,
    RequireStreetNPC = true,
    InteractionDistance = 2.2,
    SearchRadius = 12.0,
    MinQuantity = 1,
    MaxQuantity = 4,
    CooldownSeconds = 12,
    RejectChance = 18,
    RobberyChance = 4,
    PoliceCallOnRobbery = true,
    PriceVariation = 0.18, -- +/- 18%
    TargetCooldownSeconds = 240,
    MaxSalesPerHour = 45
}

Config.Progress = {
    Farm = 4500,
    Dry = 6500,
    Process = 7000,
    Package = 4500,
    Sell = 3500
}

Config.Blips = {
    Enabled = false,
    Sprite = 496,
    Scale = 0.65,
    Colour = 2
}

Config.Zones = {
    -- Farm- en productiezones zijn fictieve GTA RP-locaties.
    { id='weed_farm', label='Cannabisplanten oogsten', type='farm', drug='weed', coords=vec3(2222.2, 5577.1, 53.8), radius=22.0 },
    { id='coca_farm', label='Cocabladeren verzamelen', type='farm', drug='cocaine', coords=vec3(1540.4, 6335.2, 24.1), radius=18.0 },
    { id='poppy_farm', label='Papaver verzamelen', type='farm', drug='heroin', coords=vec3(2430.0, 4968.0, 42.3), radius=18.0 },
    { id='mushroom_farm', label='Paddenstoelen verzamelen', type='farm', drug='mushroom', coords=vec3( -575.0,  5368.0, 70.2), radius=20.0 },
    { id='chemical_farm', label='Chemische grondstoffen verzamelen', type='farm', drug='meth', coords=vec3(1391.0, 3605.0, 38.9), radius=15.0 },
    { id='opium_farm', label='Opiumgrondstof verzamelen', type='farm', drug='opium', coords=vec3( -1100.0, 4920.0, 218.0), radius=18.0 },
    { id='mdma_farm', label='MDMA-grondstof verzamelen', type='farm', drug='mdma', coords=vec3(  2510.0,  4110.0, 38.0), radius=14.0 },
    { id='syrup_farm', label='Siroopflessen verzamelen', type='farm', drug='lean', coords=vec3(  1720.0,  3290.0, 41.0), radius=14.0 },

    { id='dry_weed', label='Cannabis drogen', type='dry', drug='weed', coords=vec3(1391.2, 3605.8, 38.9), radius=2.0 },
    { id='dry_coca', label='Cocabladeren drogen', type='dry', drug='cocaine', coords=vec3(1395.2, 3605.8, 38.9), radius=2.0 },
    { id='dry_poppy', label='Papaver drogen', type='dry', drug='heroin', coords=vec3(1399.2, 3605.8, 38.9), radius=2.0 },
    { id='dry_mushroom', label='Paddenstoelen drogen', type='dry', drug='mushroom', coords=vec3(1403.2, 3605.8, 38.9), radius=2.0 },
    { id='dry_opium', label='Opiumgrondstof drogen', type='dry', drug='opium', coords=vec3(1407.2, 3605.8, 38.9), radius=2.0 },
    { id='dry_lean', label='Siroop verwerken', type='dry', drug='lean', coords=vec3(1411.2, 3605.8, 38.9), radius=2.0 },
    { id='dry_xtc', label='XTC-grondstof voorbereiden', type='dry', drug='ecstasy', coords=vec3(1415.2, 3605.8, 38.9), radius=2.0 },

    { id='process_lab', label='Drugs verwerken', type='process', coords=vec3(1090.5, -3196.6, -38.9), radius=3.0 },
    { id='package_lab', label='Drugs verpakken', type='package', coords=vec3(1094.2, -3196.6, -38.9), radius=3.0 },

    { id='sell_docks', label='Illegaal verkooppunt - haven', type='sell', coords=vec3( -323.4, -2445.8, 6.0), radius=3.0 },
    { id='sell_sandy', label='Illegaal verkooppunt - Sandy Shores', type='sell', coords=vec3(  1392.8, 3606.3, 38.9), radius=3.0 },
    { id='sell_paleto', label='Illegaal verkooppunt - Paleto Bay', type='sell', coords=vec3( -112.4, 6469.0, 31.6), radius=3.0 }
}

-- Alle items zijn spelitems; opbrengsten en stappen zijn fictieve RP-balanswaarden.
Config.Drugs = {
    weed = {
        label='Cannabis', raw='weed_leaf', dried='weed_dried', processed='weed_bag', package='weed_bag',
        farm={min=2,max=5}, dry={input=3,output=2}, process={input=2,output=1},
        packageData={input=1,output=1}, price={min=95,max=145}, policeRisk=1.0
    },
    cocaine = {
        label='Cocaïne', raw='coca_leaf', dried='coca_dried', processed='cocaine_brick', package='cocaine_bag',
        farm={min=2,max=4}, dry={input=3,output=2}, process={input=3,output=1},
        packageData={input=1,output=5}, price={min=280,max=420}, policeRisk=1.35
    },
    heroin = {
        label='Heroïne', raw='poppy_raw', dried='poppy_dried', processed='heroin_block', package='heroin_bag',
        farm={min=2,max=4}, dry={input=3,output=2}, process={input=3,output=1},
        packageData={input=1,output=5}, price={min=250,max=390}, policeRisk=1.4
    },
    meth = {
        label='Meth', raw='chem_raw', dried='chem_dried', processed='meth_crystal', package='meth_bag',
        farm={min=2,max=4}, dry={input=3,output=2}, process={input=3,output=1},
        packageData={input=1,output=5}, price={min=260,max=410}, policeRisk=1.45
    },
    mushroom = {
        label='Paddo’s', raw='mushroom_raw', dried='mushroom_dried', processed='mushroom_pack', package='mushroom_pack',
        farm={min=2,max=5}, dry={input=3,output=2}, process={input=2,output=1},
        packageData={input=1,output=1}, price={min=80,max=130}, policeRisk=0.8
    },
    opium = {
        label='Opium', raw='opium_raw', dried='opium_dried', processed='opium_resin', package='opium_pack',
        farm={min=2,max=4}, dry={input=3,output=2}, process={input=3,output=1},
        packageData={input=1,output=4}, price={min=220,max=360}, policeRisk=1.25
    },
    mdma = {
        label='MDMA', raw='mdma_powder', dried='mdma_dried', processed='mdma_pill', package='mdma_pack',
        farm={min=2,max=3}, dry={input=2,output=1}, process={input=1,output=4},
        packageData={input=4,output=1}, price={min=110,max=180}, policeRisk=1.15,
        directProcess=true
    },
    lsd = {
        label='LSD', raw='lsd_sheet_raw', dried='lsd_sheet_dry', processed='lsd_tab', package='lsd_pack',
        farm={min=1,max=2}, dry={input=2,output=1}, process={input=1,output=5},
        packageData={input=5,output=1}, price={min=100,max=170}, policeRisk=1.1
    },
    crack = {
        label='Crack', raw='cocaine_bag', dried='crack_base', processed='crack_rock', package='crack_pack',
        farm={min=0,max=0}, dry={input=2,output=1}, process={input=1,output=3},
        packageData={input=3,output=1}, price={min=180,max=280}, policeRisk=1.5, secondary=true
    },
    lean = {
        label='Lean', raw='syrup_bottle', dried='lean_base', processed='lean_bottle', package='lean_bottle',
        farm={min=2,max=3}, dry={input=2,output=1}, process={input=1,output=2},
        packageData={input=1,output=1}, price={min=90,max=150}, policeRisk=0.9
    },
    ecstasy = {
        label='XTC', raw='mdma_powder', dried='xtc_base', processed='xtc_pill', package='xtc_pack',
        farm={min=0,max=0}, dry={input=2,output=1}, process={input=1,output=5},
        packageData={input=5,output=1}, price={min=100,max=165}, policeRisk=1.1, secondary=true
    }
}

-- Itemnamen die door dit script worden gebruikt; voeg ze toe aan THOOTJE-INVENTORY.
Config.ItemLabels = {
    weed_leaf='Onbewerkte cannabis', weed_dried='Gedroogde cannabis', weed_bag='Zakje cannabis',
    coca_leaf='Cocabladeren', coca_dried='Gedroogde cocabladeren', cocaine_brick='Cocaïneblok', cocaine_bag='Zakje cocaïne',
    poppy_raw='Papavergrondstof', poppy_dried='Gedroogde papaver', heroin_block='Heroïneblok', heroin_bag='Zakje heroïne',
    chem_raw='Chemische grondstof', chem_dried='Gedroogde grondstof', meth_crystal='Methkristallen', meth_bag='Zakje meth',
    mushroom_raw='Verse paddenstoelen', mushroom_dried='Gedroogde paddenstoelen', mushroom_pack='Paddenstoelenpakket',
    opium_raw='Opiumgrondstof', opium_dried='Gedroogde opiumgrondstof', opium_resin='Opiumhars', opium_pack='Opiumverpakking',
    mdma_powder='MDMA-poeder', mdma_dried='Gedroogd MDMA-poeder', mdma_pill='MDMA-pil', mdma_pack='MDMA-verpakking',
    lsd_sheet_raw='LSD-vel', lsd_sheet_dry='Gedroogd LSD-vel', lsd_tab='LSD-tab', lsd_pack='LSD-verpakking',
    crack_base='Crack-basis', crack_rock='Cracksteen', crack_pack='Crackverpakking',
    syrup_bottle='Siroopfles', lean_base='Lean-basis', lean_bottle='Lean-fles',
    xtc_base='XTC-basis', xtc_pill='XTC-pil', xtc_pack='XTC-verpakking'
}

Config.AdminAce = 'thootje.drugs.admin'
Config.Webhook = ''
Config.AuditLogs = true
