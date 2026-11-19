Config = {}

Config.JobName = 'pechhulp'
Config.TabletCommand = 'pechhulptablet'
Config.TabletKey = 'F6'
Config.RequireDutyForActions = true
Config.RequireOnlineStaffForKitUse = true
Config.RequireSubscriptionForDiscount = true
Config.Mileage = {
    Enabled = true,
    UpdateIntervalMs = 60000,       -- elke minuut tijdens het rijden
    MinDistanceMeters = 25.0,       -- voorkomt stilstand-/teleporttikken
    MaxDistancePerUpdate = 2500.0,  -- server-side anti-abuse limiet
    ServiceReminderAtKm = 500       -- waarschuwing 500 km voor kleine beurt
}
Config.VehicleEnforcement = {
    CheckIntervalMs = 5000,
    BlockExpiredApk = true,
    BlockDisapproved = true,
    IncludeGovernmentVehicles = true,
    DefaultApkDaysForNewVehicle = 30
}
Config.Diagnostics = {
    RoadsideEngineHealth = 450.0,
    RoadsideBodyHealth = 350.0,
    RoadsideEngineDamageLimit = 650.0,
    TowVehicleModel = 'flatbed',
    TowAttachOffset = vec3(0.0, -2.2, 0.8)
}
Config.Billing = {
    Resource = 'thootje-billing',
    CreateInvoiceExport = 'CreateInvoice',
    -- Laat leeg als jouw billing-resource een andere export gebruikt.
    EnableEventFallback = false,
    CreateInvoiceEvent = 'thootje-billing:server:createInvoice'
}

-- Pas deze waarden aan op jouw THOOTJE-CORE / THOOTJE-JOBS.
Config.Inventory = {
    Add = 'AddItem', Remove = 'RemoveItem', Has = 'HasItem',
    -- exports['thootje-inventory']:AddItem(source, item, amount)
}
Config.Banking = { Resource = 'thootje-banking', InvoiceEvent = 'thootje-billing:server:createInvoice' }

Config.SubscriptionPlans = {
    basic = { label='Pechhulp Abonnement', price=2500, discount=15, repairkitDiscount=10, towDiscount=15 },
    plus  = { label='Pechhulp+ Abonnement', price=5000, discount=30, repairkitDiscount=25, towDiscount=30 }
}
Config.Invoice = { Callout=250, Repair=350, Tow=750, Inspection=500, DueDays=7 }
Config.Service = {
    batteryItem='battery', fuelCanItem='fuelcan', repairKitItem='repairkit',
    parts={ engine='scrap_engine', battery='scrap_battery', tyres='scrap_tyre', body='scrap_metal' }
}
Config.Crafting = {
    repairkit={ label='Repairkit', output=1, ingredients={ scrap_metal=3, scrap_engine=1, tools=1 } },
    battery={ label='Accu', output=1, ingredients={ scrap_metal=2, copper=2 } },
    fuelcan={ label='Brandstofkan', output=1, ingredients={ scrap_metal=1, plastic=2 } }
}
Config.Workshop = {
    { label='Hoofdpost Pechhulp', coords=vec3( -211.2, -1324.1, 30.9) },
    { label='Werkplaats magazijn', coords=vec3(-205.8, -1318.0, 31.1) }
}
Config.Inspection = {
    ServiceIntervalKm=5000, ApkIntervalDays=30,
    DefaultRoadworthy=true, FineForDrivingDisapproved=5000,
    GovernmentJobs={'police','ambulance','fire','government'}
}
Config.ScrapYard = { coords=vec3( 2350.5, 3133.2, 48.2), payoutPerPart=125 }
Config.PechhulpSpawn = vec4(-205.0,-1308.0,31.2,90.0)
Config.AllowedVehicleClasses = nil -- nil = alle voertuigen

Config.Messages = { prefix='Pechhulp' }
