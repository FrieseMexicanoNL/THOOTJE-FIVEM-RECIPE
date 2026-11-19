Thootje = Thootje or {}
Thootje.Players = Thootje.Players or {}
Thootje.Callbacks = Thootje.Callbacks or {}

local function getPlayer(src)
    return Thootje.Players[tonumber(src)]
end

Thootje.Functions.GetPlayer = getPlayer
Thootje.Functions.GetPlayerData = Thootje.GetPlayerData

function Thootje.Functions.AddMoney(src, account, amount, reason)
    local p = getPlayer(src)
    amount = math.floor(tonumber(amount) or 0)
    if not p or amount <= 0 or p.accounts[account] == nil then return false end
    p.accounts[account] = p.accounts[account] + amount
    TriggerClientEvent('thootje:client:updateData', src, Thootje.GetPlayerData(src))
    TriggerEvent('thootje:server:moneyChanged', src, account, amount, 'add', reason or 'unknown')
    return true
end

function Thootje.Functions.RemoveMoney(src, account, amount, reason)
    local p = getPlayer(src)
    amount = math.floor(tonumber(amount) or 0)
    if not p or amount <= 0 or p.accounts[account] == nil or p.accounts[account] < amount then return false end
    p.accounts[account] = p.accounts[account] - amount
    TriggerClientEvent('thootje:client:updateData', src, Thootje.GetPlayerData(src))
    TriggerEvent('thootje:server:moneyChanged', src, account, amount, 'remove', reason or 'unknown')
    return true
end

function Thootje.Functions.SetJob(src, name, label, grade, gradeLabel)
    local p = getPlayer(src)
    if not p or type(name) ~= 'string' then return false end
    p.job = {
        name = name, label = label or name, grade = tonumber(grade) or 0,
        gradeLabel = gradeLabel or 'Medewerker'
    }
    TriggerClientEvent('thootje:client:updateData', src, Thootje.GetPlayerData(src))
    TriggerEvent('thootje:server:jobChanged', src, p.job)
    return true
end

function Thootje.Functions.AddItem(src, itemName, amount, metadata)
    local p = getPlayer(src)
    amount = math.floor(tonumber(amount) or 1)
    local item = Config.Items[itemName]
    if not p or not item or amount < 1 then return false, 'Ongeldig item of aantal.' end

    local currentWeight = 0
    for _, slot in pairs(p.inventory) do
        local def = Config.Items[slot.name]
        if def then currentWeight = currentWeight + (def.weight * slot.count) end
    end
    if currentWeight + (item.weight * amount) > Config.MaxInventoryWeight then
        return false, 'Je inventory is te zwaar.'
    end

    if item.stack then
        for _, slot in pairs(p.inventory) do
            if slot.name == itemName then
                slot.count = slot.count + amount
                TriggerClientEvent('thootje:client:updateData', src, Thootje.GetPlayerData(src))
                return true
            end
        end
    end

    local used = {}
    for _, slot in pairs(p.inventory) do used[tonumber(slot.slot)] = true end
    local freeSlot
    for i = 1, Config.InventorySlots do
        if not used[i] then freeSlot = i break end
    end
    if not freeSlot then return false, 'Je inventory zit vol.' end

    p.inventory[#p.inventory + 1] = {
        name = itemName, label = item.label, count = amount,
        slot = freeSlot, metadata = metadata or {}
    }
    TriggerClientEvent('thootje:client:updateData', src, Thootje.GetPlayerData(src))
    return true
end

function Thootje.Functions.RemoveItem(src, itemName, amount)
    local p = getPlayer(src)
    amount = math.floor(tonumber(amount) or 1)
    if not p or amount < 1 then return false end
    for i = #p.inventory, 1, -1 do
        local slot = p.inventory[i]
        if slot.name == itemName then
            if slot.count < amount then return false end
            slot.count = slot.count - amount
            if slot.count == 0 then table.remove(p.inventory, i) end
            TriggerClientEvent('thootje:client:updateData', src, Thootje.GetPlayerData(src))
            return true
        end
    end
    return false
end

exports('GetCoreObject', function() return Thootje end)
exports('GetPlayer', getPlayer)
exports('GetPlayerData', Thootje.GetPlayerData)
exports('AddMoney', Thootje.Functions.AddMoney)
exports('RemoveMoney', Thootje.Functions.RemoveMoney)
exports('SetJob', Thootje.Functions.SetJob)
exports('AddItem', Thootje.Functions.AddItem)
exports('RemoveItem', Thootje.Functions.RemoveItem)

RegisterNetEvent('thootje:server:requestInventory', function()
    local src = source
    local p = Thootje.Players[src]
    if p then TriggerClientEvent('thootje:client:openInventory', src, p.inventory) end
end)

AddEventHandler('playerJoining', function()
    local src = source
    CreateThread(function()
        Wait(1500)
        if GetPlayerName(src) then Thootje.LoadPlayer(src) end
    end)
end)

AddEventHandler('playerDropped', function()
    local src = source
    Thootje.SavePlayer(src)
    Thootje.Players[src] = nil
end)

CreateThread(function()
    while true do
        Wait(300000)
        for src in pairs(Thootje.Players) do Thootje.SavePlayer(src) end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for src in pairs(Thootje.Players) do Thootje.SavePlayer(src) end
end)
