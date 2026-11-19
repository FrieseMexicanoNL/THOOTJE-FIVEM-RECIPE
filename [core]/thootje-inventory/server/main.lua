local Core = exports['thootje-core']:GetCoreObject()
local UsableItems = {}
local Drops = {}
local RateLimit = {}

local function debug(...)
    if Config.Debug then print('^3[THOOTJE-INVENTORY]^7', ...) end
end

local function player(src)
    return Core.Functions.GetPlayer(tonumber(src))
end

local function notify(src, msg)
    TriggerClientEvent('thootje-inventory:client:notify', src, msg)
end

local function itemDef(name)
    return Config.Items[name]
end

local function weightOf(items)
    local weight = 0
    for _, slot in pairs(items or {}) do
        local def = itemDef(slot.name)
        if def then weight = weight + (def.weight * (tonumber(slot.count) or 0)) end
    end
    return weight
end

local function findSlot(items, slotId)
    for index, slot in pairs(items or {}) do
        if tonumber(slot.slot) == tonumber(slotId) then return index, slot end
    end
end

local function nextSlot(items)
    local used = {}
    for _, slot in pairs(items or {}) do used[tonumber(slot.slot)] = true end
    for i = 1, Config.Slots do if not used[i] then return i end end
end

local function canCarry(p, name, count)
    local def = itemDef(name)
    if not def then return false, Config.Text.invalid end
    if weightOf(p.inventory) + def.weight * count > Config.MaxWeight then return false, Config.Text.tooHeavy end
    if def.stack then
        for _, slot in pairs(p.inventory) do
            if slot.name == name then return true end
        end
    end
    local needed = def.stack and 1 or count
    local free = 0
    for i = 1, Config.Slots do if not findSlot(p.inventory, i) then free = free + 1 end end
    if free < needed then return false, Config.Text.full end
    return true
end

local function push(src, p)
    TriggerClientEvent('thootje-inventory:client:update', src, {
        items = p.inventory,
        weight = weightOf(p.inventory),
        maxWeight = Config.MaxWeight,
        slots = Config.Slots,
        hotbarSlots = Config.HotbarSlots,
        definitions = Config.Items,
        rarities = Config.Rarities
    })
    TriggerClientEvent('thootje:client:updateData', src, Core.Functions.GetPlayerData(src))
end

local function addItem(p, name, count, metadata, preferredSlot)
    local def = itemDef(name)
    count = math.floor(tonumber(count) or 1)
    if not def or count < 1 then return false, Config.Text.invalid end
    if weightOf(p.inventory) + def.weight * count > Config.MaxWeight then return false, Config.Text.tooHeavy end

    if def.stack then
        for _, slot in pairs(p.inventory) do
            if slot.name == name and (not preferredSlot or tonumber(slot.slot) == tonumber(preferredSlot)) then
                slot.count = slot.count + count
                return true
            end
        end
    end

    if def.stack then
        local slotId = tonumber(preferredSlot) or nextSlot(p.inventory)
        if not slotId or slotId < 1 or slotId > Config.Slots or findSlot(p.inventory, slotId) then
            slotId = nextSlot(p.inventory)
        end
        if not slotId then return false, Config.Text.full end
        p.inventory[#p.inventory + 1] = { name = name, label = def.label, count = count, slot = slotId, metadata = metadata or {} }
    else
        for _ = 1, count do
            local slotId = nextSlot(p.inventory)
            if not slotId then return false, Config.Text.full end
            p.inventory[#p.inventory + 1] = { name = name, label = def.label, count = 1, slot = slotId, metadata = metadata or {} }
        end
    end
    return true
end

local function removeAt(p, slotId, count)
    local index, slot = findSlot(p.inventory, slotId)
    count = math.floor(tonumber(count) or 1)
    if not index or count < 1 or slot.count < count then return false end
    slot.count = slot.count - count
    if slot.count <= 0 then table.remove(p.inventory, index) end
    return true, slot
end

local function rateOk(src, key, cooldown)
    local now = GetGameTimer()
    RateLimit[src] = RateLimit[src] or {}
    if RateLimit[src][key] and now - RateLimit[src][key] < cooldown then return false end
    RateLimit[src][key] = now
    return true
end

RegisterNetEvent('thootje-inventory:server:requestOpen', function()
    local src = source
    local p = player(src)
    if not p then return end
    push(src, p)
    TriggerClientEvent('thootje-inventory:client:open', src, {
        items = p.inventory, weight = weightOf(p.inventory),
        maxWeight = Config.MaxWeight, slots = Config.Slots,
        hotbarSlots = Config.HotbarSlots, definitions = Config.Items,
        rarities = Config.Rarities, title = Config.Text.title, subtitle = Config.Text.subtitle
    })
end)

RegisterNetEvent('thootje-inventory:server:move', function(fromSlot, toSlot, amount)
    local src = source
    if not rateOk(src, 'move', 80) then return end
    local p = player(src)
    if not p then return end
    fromSlot, toSlot = tonumber(fromSlot), tonumber(toSlot)
    amount = math.floor(tonumber(amount) or 0)
    if not fromSlot or not toSlot or fromSlot < 1 or fromSlot > Config.Slots or toSlot < 1 or toSlot > Config.Slots or fromSlot == toSlot then return end
    local _, from = findSlot(p.inventory, fromSlot)
    local toIndex, to = findSlot(p.inventory, toSlot)
    if not from then return end

    if not to then
        from.slot = toSlot
    elseif to.name == from.name and itemDef(from.name).stack then
        local moveCount = amount > 0 and math.min(amount, from.count) or from.count
        to.count = to.count + moveCount
        removeAt(p, fromSlot, moveCount)
    else
        local fromIndex = findSlot(p.inventory, fromSlot)
        local old = from.slot
        from.slot = to.slot
        to.slot = old
    end
    push(src, p)
end)

RegisterNetEvent('thootje-inventory:server:use', function(slotId)
    local src = source
    if not rateOk(src, 'use', 250) then return end
    local p = player(src)
    if not p then return end
    local _, slot = findSlot(p.inventory, slotId)
    if not slot then return end
    local def = itemDef(slot.name)
    if not def or not def.usable then return end

    local handler = UsableItems[slot.name]
    if handler then
        local ok, err = pcall(handler, src, slot)
        if not ok then print(('^1[THOOTJE-INVENTORY] usable error %s: %s^7'):format(slot.name, err)) end
    elseif def.effect then
        if def.effect == 'eat' or def.effect == 'drink' or def.effect == 'heal' then
            removeAt(p, slotId, 1)
            TriggerClientEvent('thootje-inventory:client:effect', src, def.effect, Config.UseEffects[def.effect])
            notify(src, Config.Text.used)
        else
            TriggerClientEvent('thootje-inventory:client:itemUsed', src, slot.name, slot.metadata or {})
        end
    else
        TriggerClientEvent('thootje-inventory:client:itemUsed', src, slot.name, slot.metadata or {})
    end
    push(src, p)
end)

RegisterNetEvent('thootje-inventory:server:drop', function(slotId, count)
    local src = source
    if not Config.AllowDrop or not rateOk(src, 'drop', 300) then return end
    local p = player(src)
    if not p then return end
    local _, slot = findSlot(p.inventory, slotId)
    count = math.floor(tonumber(count) or 1)
    if not slot or count < 1 or count > slot.count then return end
    local name = slot.name
    if not removeAt(p, slotId, count) then return end
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local id = ('%s_%s'):format(src, GetGameTimer())
    Drops[id] = { name = name, count = count, coords = coords, created = os.time() }
    push(src, p)
    notify(src, Config.Text.dropped)
end)

RegisterNetEvent('thootje-inventory:server:pickup', function(dropId)
    local src = source
    if not rateOk(src, 'pickup', 500) then return end
    local p = player(src)
    local drop = Drops[tostring(dropId)]
    if not p or not drop then return end
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    if #(coords - drop.coords) > Config.DropDistance + 1.0 then return end
    local ok, err = canCarry(p, drop.name, drop.count)
    if not ok then notify(src, err) return end
    local added, addErr = addItem(p, drop.name, drop.count)
    if not added then notify(src, addErr) return end
    Drops[tostring(dropId)] = nil
    push(src, p)
    notify(src, Config.Text.pickedUp)
end)

RegisterNetEvent('thootje-inventory:server:pickupNearest', function()
    local src = source
    local p = player(src)
    if not p or not rateOk(src, 'pickup', 500) then return end
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local nearestId, nearestDistance
    for id, drop in pairs(Drops) do
        local distance = #(coords - drop.coords)
        if distance <= Config.DropDistance and (not nearestDistance or distance < nearestDistance) then
            nearestId, nearestDistance = id, distance
        end
    end
    if not nearestId then notify(src, 'Er ligt geen item in de buurt.') return end
    local drop = Drops[nearestId]
    local ok, err = canCarry(p, drop.name, drop.count)
    if not ok then notify(src, err) return end
    local added, addErr = addItem(p, drop.name, drop.count)
    if not added then notify(src, addErr) return end
    Drops[nearestId] = nil
    push(src, p)
    notify(src, Config.Text.pickedUp)
end)

RegisterNetEvent('thootje-inventory:server:give', function(slotId, target, count)
    local src = source
    if not Config.AllowGive or not rateOk(src, 'give', 500) then return end
    local p, targetPlayer = player(src), player(target)
    target = tonumber(target)
    if not p or not target or target == src or not targetPlayer then return end
    local sourcePed, targetPed = GetPlayerPed(src), GetPlayerPed(target)
    if #(GetEntityCoords(sourcePed) - GetEntityCoords(targetPed)) > Config.MaxGiveDistance then
        notify(src, Config.Text.noPlayer) return
    end
    local _, slot = findSlot(p.inventory, slotId)
    count = math.floor(tonumber(count) or 1)
    if not slot or count < 1 or count > slot.count then return end
    local ok, err = canCarry(targetPlayer, slot.name, count)
    if not ok then notify(src, err) return end

    local name, metadata = slot.name, slot.metadata
    if not removeAt(p, slotId, count) then return end
    local added, addErr = addItem(targetPlayer, name, count, metadata)
    if not added then addItem(p, name, count, metadata, slotId) notify(src, addErr) return end
    push(src, p); push(target, targetPlayer)
    notify(src, Config.Text.given); notify(target, Config.Text.received)
end)

RegisterNetEvent('thootje-inventory:server:split', function(slotId, count, toSlot)
    local src = source
    local p = player(src)
    if not Config.AllowSplit or not p or not rateOk(src, 'split', 150) then return end
    local _, slot = findSlot(p.inventory, slotId)
    count, toSlot = math.floor(tonumber(count) or 0), tonumber(toSlot)
    if not slot or not itemDef(slot.name).stack or count < 1 or count >= slot.count then return end
    if not toSlot or toSlot < 1 or toSlot > Config.Slots or findSlot(p.inventory, toSlot) then return end
    slot.count = slot.count - count
    p.inventory[#p.inventory + 1] = { name = slot.name, label = slot.label, count = count, slot = toSlot, metadata = slot.metadata or {} }
    push(src, p)
end)

function exportsAddItem(src, name, count, metadata)
    local p = player(src)
    if not p then return false end
    local ok, err = addItem(p, name, count, metadata)
    if ok then push(src, p) end
    return ok, err
end

exports('AddItem', exportsAddItem)
exports('RemoveItem', function(src, name, count)
    local p = player(src)
    if not p then return false end
    local remaining = math.floor(tonumber(count) or 1)
    for i = #p.inventory, 1, -1 do
        local slot = p.inventory[i]
        if slot.name == name and remaining > 0 then
            local take = math.min(slot.count, remaining)
            slot.count = slot.count - take
            remaining = remaining - take
            if slot.count <= 0 then table.remove(p.inventory, i) end
        end
    end
    if remaining > 0 then return false end
    push(src, p)
    return true
end)
exports('GetInventory', function(src)
    local p = player(src)
    return p and p.inventory or nil
end)
exports('RegisterUsableItem', function(name, cb)
    assert(itemDef(name), ('Unknown inventory item: %s'):format(tostring(name)))
    assert(type(cb) == 'function', 'Callback must be a function')
    UsableItems[name] = cb
end)

CreateThread(function()
    while true do
        Wait(60000)
        local now = os.time()
        for id, drop in pairs(Drops) do
            if now - drop.created > Config.DropLifetimeHours * 3600 then Drops[id] = nil end
        end
    end
end)

AddEventHandler('playerDropped', function()
    RateLimit[source] = nil
end)
