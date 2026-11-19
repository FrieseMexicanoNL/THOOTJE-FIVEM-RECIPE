local Cooldowns, TargetSales, HourlySales = {}, {}, {}
local SaleHistory = {}

local function logAction(src, action, detail)
    if not Config.AuditLogs then return end
    local identifier = THOOTJE_DRUGS.GetIdentifier(src) or 'unknown'
    MySQL.insert('INSERT INTO thootje_drugs_logs (identifier, player_name, action, details) VALUES (?, ?, ?, ?)',
        { identifier, GetPlayerName(src) or 'unknown', action, json.encode(detail or {}) })
end

local function getZone(zoneId)
    for _, zone in ipairs(Config.Zones) do
        if zone.id == zoneId then return zone end
    end
end

local function nearZone(src, zone, extra)
    if not zone then return false end
    local ped = GetPlayerPed(src)
    if ped == 0 then return false end
    local coords = GetEntityCoords(ped)
    return #(coords - zone.coords) <= (zone.radius or Config.InteractDistance) + (extra or 0.0)
end

local function canAct(src)
    if Config.RequireCharacter and not THOOTJE_DRUGS.GetIdentifier(src) then return false end
    if Config.RequireOnFoot and GetVehiclePedIsIn(GetPlayerPed(src), false) ~= 0 then return false end
    return true
end

local function cooldown(src, key, seconds)
    local now = os.time()
    local id = tostring(src) .. ':' .. key
    if Cooldowns[id] and Cooldowns[id] > now then
        THOOTJE_DRUGS.Notify(src, ('Wacht nog %s seconden.'):format(Cooldowns[id] - now), 'error')
        return false
    end
    Cooldowns[id] = now + seconds
    return true
end

local function processStage(src, zoneId, stage, drugKey)
    local zone = getZone(zoneId)
    local drug = Config.Drugs[drugKey]
    if not zone or not drug or zone.type ~= stage or not nearZone(src, zone, 1.5) or not canAct(src) then
        return THOOTJE_DRUGS.Notify(src, 'Je staat niet op de juiste locatie.', 'error')
    end
    if stage ~= 'farm' and zone.drug and zone.drug ~= drugKey then
        return THOOTJE_DRUGS.Notify(src, 'Deze locatie is niet geschikt voor dit product.', 'error')
    end
    local cd = Config.Progress[stage] / 1000
    if not cooldown(src, stage .. ':' .. drugKey, math.max(2, math.ceil(cd))) then return end

    local input, output, itemIn, itemOut
    if stage == 'farm' then
        if drug.secondary or not drug.farm or drug.farm.max <= 0 then
            return THOOTJE_DRUGS.Notify(src, 'Deze variant wordt gemaakt uit een ander product.', 'error')
        end
        output = math.random(drug.farm.min, drug.farm.max)
        itemOut = drug.raw
    elseif stage == 'dry' then
        input, output, itemIn, itemOut = drug.dry.input, drug.dry.output, drug.raw, drug.dried
    elseif stage == 'process' then
        input, output, itemIn, itemOut = drug.process.input, drug.process.output, drug.dried, drug.processed
        if drug.directProcess then itemIn = drug.raw end
        if drugKey == 'crack' then itemIn = 'cocaine_bag' end
        if drugKey == 'lean' then itemIn = 'syrup_bottle' end
        if drugKey == 'ecstasy' then itemIn = 'mdma_powder' end
    elseif stage == 'package' then
        input, output, itemIn, itemOut = drug.packageData.input, drug.packageData.output, drug.processed, drug.package
    else
        return
    end

    if input and not THOOTJE_DRUGS.HasItem(src, itemIn, input) then
        return THOOTJE_DRUGS.Notify(src, ('Je hebt %sx %s nodig.'):format(input, Config.ItemLabels[itemIn] or itemIn), 'error')
    end
    if input and not THOOTJE_DRUGS.RemoveItem(src, itemIn, input) then
        return THOOTJE_DRUGS.Notify(src, 'Het verwijderen van items is mislukt.', 'error')
    end
    if not THOOTJE_DRUGS.AddItem(src, itemOut, output) then
        if input then THOOTJE_DRUGS.AddItem(src, itemIn, input) end
        return THOOTJE_DRUGS.Notify(src, 'Je inventaris kon het product niet toevoegen.', 'error')
    end
    THOOTJE_DRUGS.Notify(src, ('Je hebt %sx %s ontvangen.'):format(output, Config.ItemLabels[itemOut] or itemOut), 'success')
    logAction(src, stage, { drug = drugKey, input = input, inputItem = itemIn, output = output, outputItem = itemOut })
end

RegisterNetEvent('thootje-drugs:server:stage', function(zoneId, stage, drugKey)
    local src = source
    if type(zoneId) ~= 'string' or type(stage) ~= 'string' or type(drugKey) ~= 'string' then return end
    processStage(src, zoneId, stage, drugKey)
end)

local function policeAlert(src, drugKey, coords, force)
    if not Config.Police.Enabled then return end
    if not force and math.random(100) > Config.Police.Chance then return end
    local now = os.time()
    local id = tostring(src)
    if SaleHistory[id] and SaleHistory[id] > now then return end
    SaleHistory[id] = now + Config.Police.CooldownSeconds
    local payload = {
        code = Config.Police.DispatchCode,
        title = Config.Police.DispatchTitle,
        description = Config.Police.DispatchDescription .. ' (' .. (Config.Drugs[drugKey] and Config.Drugs[drugKey].label or 'onbekend') .. ')',
        coords = { x = coords.x, y = coords.y, z = coords.z },
        street = 'Onbekende locatie',
        source = src,
        duration = Config.Police.BlipDuration
    }
    -- Compatibiliteit: eigen server-event in politiejob, plus fallback naar generieke dispatch.
    TriggerEvent(Config.Police.Event, payload)
    TriggerEvent('thootje-politiejob:server:customDispatch', payload)
    logAction(src, 'police_alert', payload)
end

local function countOnDutyPolice()
    local count = 0
    for _, player in ipairs(GetPlayers()) do
        if THOOTJE_DRUGS.IsPolice(tonumber(player)) then count = count + 1 end
    end
    return count
end

RegisterNetEvent('thootje-drugs:server:sellToNPC', function(netId)
    local src = source
    if not Config.Selling.Enabled or not canAct(src) then return end
    if not cooldown(src, 'npc_sale', Config.Selling.CooldownSeconds) then return end
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local npc = NetworkGetEntityFromNetworkId(tonumber(netId) or 0)
    if npc == 0 or not DoesEntityExist(npc) or not IsEntityAPed(npc) or IsPedAPlayer(npc) then
        return THOOTJE_DRUGS.Notify(src, 'Geen geldige NPC gevonden.', 'error')
    end
    if #(GetEntityCoords(npc) - coords) > Config.Selling.InteractionDistance + 1.0 then
        return THOOTJE_DRUGS.Notify(src, 'De persoon staat te ver weg.', 'error')
    end
    if IsPedInAnyVehicle(npc, false) or IsPedDeadOrDying(npc, true) then
        return THOOTJE_DRUGS.Notify(src, 'Deze persoon is geen geschikte koper.', 'error')
    end

    local now = os.time()
    local targetKey = tostring(netId)
    if TargetSales[targetKey] and TargetSales[targetKey] > now then
        return THOOTJE_DRUGS.Notify(src, 'Deze persoon heeft al een aanbod gehad.', 'error')
    end
    TargetSales[targetKey] = now + Config.Selling.TargetCooldownSeconds

    local soldDrug, soldItem
    for drugKey, drug in pairs(Config.Drugs) do
        if THOOTJE_DRUGS.HasItem(src, drug.package, Config.Selling.MinQuantity) then
            soldDrug, soldItem = drugKey, drug.package
            break
        end
    end
    if not soldDrug then return THOOTJE_DRUGS.Notify(src, 'Je hebt niets verkoopbaars bij je.', 'error') end

    local drug = Config.Drugs[soldDrug]
    local qty = math.random(Config.Selling.MinQuantity, Config.Selling.MaxQuantity)
    while qty > 1 and not THOOTJE_DRUGS.HasItem(src, soldItem, qty) do qty = qty - 1 end
    if math.random(100) <= Config.Selling.RejectChance then
        THOOTJE_DRUGS.Notify(src, 'De persoon weigert je aanbod.', 'error')
        if math.random(100) <= Config.Police.Chance then policeAlert(src, soldDrug, coords, true) end
        logAction(src, 'npc_sale_rejected', { drug = soldDrug })
        return
    end
    if not THOOTJE_DRUGS.RemoveItem(src, soldItem, qty) then
        return THOOTJE_DRUGS.Notify(src, 'Verkoop mislukt: items konden niet worden verwijderd.', 'error')
    end

    local basePrice = math.random(drug.price.min, drug.price.max)
    local variation = 1.0 + ((math.random() * 2 - 1) * Config.Selling.PriceVariation)
    local total = math.floor(basePrice * qty * variation * (drug.policeRisk or 1.0))
    local robbery = math.random(100) <= Config.Selling.RobberyChance
    if robbery then
        THOOTJE_DRUGS.Notify(src, 'De koper grist je spullen en rent weg!', 'error')
        policeAlert(src, soldDrug, coords, true)
        logAction(src, 'npc_robbery', { drug = soldDrug, quantity = qty })
        return
    end

    -- Gebruik de banking-export indien aanwezig; anders core cash-event.
    local paid = false
    if GetResourceState('thootje-banking') == 'started' then
        local ok, result = pcall(function()
            return exports['thootje-banking']:AddCashMoney(src, total, 'Illegale verkoop')
        end)
        paid = ok and result ~= false
    end
    if not paid then
        TriggerEvent('thootje-core:server:addMoney', src, 'cash', total, 'drugs-sale')
    end
    THOOTJE_DRUGS.Notify(src, ('Verkocht: %sx %s voor $%s.'):format(qty, drug.label, total), 'success')
    policeAlert(src, soldDrug, coords, false)
    logAction(src, 'npc_sale', { drug = soldDrug, item = soldItem, quantity = qty, amount = total })
end)

RegisterNetEvent('thootje-drugs:server:sellAtPoint', function(zoneId)
    local src = source
    local zone = getZone(zoneId)
    if not zone or zone.type ~= 'sell' or not nearZone(src, zone, 1.5) or not canAct(src) then
        return THOOTJE_DRUGS.Notify(src, 'Je bent niet bij een verkooppunt.', 'error')
    end
    -- Verkooplocatie opent een bulk-inkoopactie; max 10 items per keer.
    local sold, total = 0, 0
    for drugKey, drug in pairs(Config.Drugs) do
        local amount = 0
        while amount < 10 and THOOTJE_DRUGS.HasItem(src, drug.package, amount + 1) do amount = amount + 1 end
        if amount > 0 then
            local unit = math.random(drug.price.min, drug.price.max)
            if THOOTJE_DRUGS.RemoveItem(src, drug.package, amount) then
                sold = sold + amount
                total = total + amount * unit
                policeAlert(src, drugKey, GetEntityCoords(GetPlayerPed(src)), false)
            end
        end
    end
    if sold == 0 then return THOOTJE_DRUGS.Notify(src, 'Je hebt geen verpakte producten om te verkopen.', 'error') end
    local paid = false
    if GetResourceState('thootje-banking') == 'started' then
        local ok, result = pcall(function()
            return exports['thootje-banking']:AddCashMoney(src, total, 'Illegale groothandel')
        end)
        paid = ok and result ~= false
    end
    if not paid then TriggerEvent('thootje-core:server:addMoney', src, 'cash', total, 'drugs-wholesale') end
    THOOTJE_DRUGS.Notify(src, ('Groothandel: %s verpakkingen verkocht voor $%s.'):format(sold, total), 'success')
    logAction(src, 'bulk_sale', { quantity = sold, amount = total, zone = zoneId })
end)

RegisterNetEvent('thootje-drugs:server:policeCheck', function()
    local src = source
    if not THOOTJE_DRUGS.IsPolice(src) then return end
    TriggerClientEvent('thootje-drugs:client:policeCount', src, countOnDutyPolice())
end)

RegisterCommand('drugstats', function(src)
    if src == 0 or IsPlayerAceAllowed(src, Config.AdminAce) then
        local result = MySQL.query.await('SELECT action, COUNT(*) AS total FROM thootje_drugs_logs GROUP BY action ORDER BY total DESC')
        if src == 0 then
            print('[thootje-drugs] Statistieken:')
            for _, row in ipairs(result or {}) do print(('%s: %s'):format(row.action, row.total)) end
        else
            TriggerClientEvent('chat:addMessage', src, { args = { 'THOOTJE DRUGS', 'Statistieken staan in de serverconsole.' } })
        end
    end
end, false)

AddEventHandler('playerDropped', function()
    local prefix = tostring(source) .. ':'
    for key in pairs(Cooldowns) do if key:sub(1, #prefix) == prefix then Cooldowns[key] = nil end end
end)
