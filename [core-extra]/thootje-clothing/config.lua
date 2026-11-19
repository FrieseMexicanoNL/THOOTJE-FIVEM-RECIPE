Config = {}

Config.OpenCommand = 'clothing'
Config.WardrobeCommand = 'wardrobe'
Config.OpenKey = 'F5'
Config.JobWardrobeCommand = 'joboutfit'
Config.HairCommand = 'kapsalon'
Config.TattooCommand = 'tattoos'
Config.FaceCommand = 'gezicht'

Config.RequireFreemodePed = true

Config.Shops = {
    { label='Ponsonbys - Rockford Hills', coords=vec3(-709.8,-151.9,37.4), heading=120.0 },
    { label='Suburban - Vespucci', coords=vec3(-1193.6,-772.3,17.3), heading=35.0 },
    { label='Discount Store - Strawberry', coords=vec3(72.3,-1399.1,29.4), heading=270.0 },
    { label='Binco - Textile City', coords=vec3(427.0,-800.2,29.5), heading=90.0 }
}
Config.Wardrobes = {} -- Voeg hier je eigen kledingkast-coördinaten toe.
Config.HairSalons = {
    { label='Kapsalon - Rockford Hills', coords=vec3(-817.0, -183.0, 37.6), heading=120.0 },
    { label='Kapsalon - Sandy Shores', coords=vec3(1931.0, 3730.0, 32.8), heading=210.0 }
}
Config.TattooShops = {
    { label='Tattoo Shop - Vinewood', coords=vec3(1322.6, -1651.9, 52.3), heading=130.0 },
    { label='Tattoo Shop - Sandy Shores', coords=vec3(1864.6, 3747.7, 33.0), heading=30.0 }
}

Config.MarkerDistance = 12.0
Config.InteractDistance = 1.8
Config.ShopPrice = 250
Config.HairPrice = 350
Config.FacePrice = 500
Config.TattooPrice = 750
Config.FreeWardrobe = true
Config.ChargeForShopPurchase = true
Config.ChargeForHair = true
Config.ChargeForFace = true
Config.ChargeForTattoo = true

-- Koppel deze export aan jouw daadwerkelijke THOOTJE-BANKING API.
-- Verwachte signature: exports['thootje-banking']:RemoveCashMoney(source, amount, reason)
Config.Banking = { Resource='thootje-banking', RemoveCashExport='RemoveCashMoney' }

Config.MaxSavedOutfits = 30
Config.MaxDrawable = 250
Config.MaxTexture = 50
Config.AllowSaveOutfitsAtShop = true
Config.AllowSaveOutfitsAtWardrobe = true
Config.DefaultOutfitName = 'Mijn outfit'

Config.Categories = {
    { id='mask', label='Maskers', type='component', component=1, icon='◈' },
    { id='arms', label='Armen', type='component', component=3, icon='✦' },
    { id='pants', label='Broeken', type='component', component=4, icon='▤' },
    { id='bags', label='Tassen', type='component', component=5, icon='▣' },
    { id='shoes', label='Schoenen', type='component', component=6, icon='⌁' },
    { id='accessories', label='Accessoires', type='component', component=7, icon='◇' },
    { id='undershirt', label='Onderkleding', type='component', component=8, icon='▱' },
    { id='vest', label='Bodywarmers', type='component', component=9, icon='▥' },
    { id='decals', label='Emblemen', type='component', component=10, icon='✧' },
    { id='tops', label='Jassen & shirts', type='component', component=11, icon='▰' },
    { id='hat', label='Hoeden', type='prop', prop=0, icon='♢' },
    { id='glasses', label='Brillen', type='prop', prop=1, icon='◉' },
    { id='ears', label='Ooraccessoires', type='prop', prop=2, icon='⌑' },
    { id='watch', label='Horloges', type='prop', prop=6, icon='◷' },
    { id='bracelet', label='Armbanden', type='prop', prop=7, icon='⌁' }
}

-- Pas drawable/texture aan op jouw kledingpakket. Deze waarden zijn voorbeelduniformen.
Config.JobUniforms = {
    police = {
        label='Politie-uniformen', minGrade=0,
        male={ components={ [3]={drawable=0,texture=0}, [4]={drawable=35,texture=0}, [6]={drawable=25,texture=0}, [8]={drawable=58,texture=0}, [11]={drawable=55,texture=0} }, props={ [0]={drawable=-1,texture=0} } },
        female={ components={ [3]={drawable=0,texture=0}, [4]={drawable=34,texture=0}, [6]={drawable=25,texture=0}, [8]={drawable=35,texture=0}, [11]={drawable=48,texture=0} }, props={ [0]={drawable=-1,texture=0} } }
    },
    ambulance = {
        label='EMS-uniformen', minGrade=0,
        male={ components={ [3]={drawable=85,texture=0}, [4]={drawable=96,texture=0}, [6]={drawable=25,texture=0}, [8]={drawable=15,texture=0}, [11]={drawable=250,texture=0} }, props={} },
        female={ components={ [3]={drawable=89,texture=0}, [4]={drawable=99,texture=0}, [6]={drawable=25,texture=0}, [8]={drawable=14,texture=0}, [11]={drawable=258,texture=0} }, props={} }
    }
}

-- GTA tattoo collection/hash combinaties moeten passen bij jouw ped/DLC.
-- Vul hier geldige tattoos in; lege lijst voorkomt ongeldige native calls.
Config.Tattoos = {
    { label='Tattoo voorbeeld (vervang collection/hash)', collection='mpbusiness_overlays', name='MP_Buis_M_Neck_001', gender='male' },
    { label='Tattoo voorbeeld (vervang collection/hash)', collection='mpbusiness_overlays', name='MP_Buis_F_Neck_001', gender='female' }
}
