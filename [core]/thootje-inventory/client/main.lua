local isOpen = false
local currentData = {}

local function setOpen(state)
    isOpen = state
    SetNuiFocus(state, state)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({ action = state and 'open' or 'close', data = currentData })
end

RegisterCommand(Config.OpenCommand, function()
    if isOpen then return end
    TriggerServerEvent('thootje-inventory:server:requestOpen')
end, false)
RegisterKeyMapping(Config.OpenCommand, 'Open THOOTJE inventory', 'keyboard', Config.OpenKey)

RegisterCommand('pickup', function()
    TriggerServerEvent('thootje-inventory:server:pickupNearest')
end, false)

RegisterNetEvent('thootje-inventory:client:open', function(data)
    currentData = data or {}
    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', data = currentData })
end)

RegisterNetEvent('thootje-inventory:client:update', function(data)
    currentData = data or {}
    SendNUIMessage({ action = 'update', data = currentData })
end)

RegisterNetEvent('thootje-inventory:client:notify', function(message)
    SendNUIMessage({ action = 'notify', message = message })
end)

RegisterNetEvent('thootje-inventory:client:effect', function(effect, values)
    local ped = PlayerPedId()
    values = values or {}
    if effect == 'eat' or effect == 'drink' then
        local health = GetEntityHealth(ped)
        SetEntityHealth(ped, math.min(GetEntityMaxHealth(ped), health + (values.health or 0)))
        if values.armour then SetPedArmour(ped, math.min(100, GetPedArmour(ped) + values.armour)) end
    elseif effect == 'heal' then
        local health = GetEntityHealth(ped)
        SetEntityHealth(ped, math.min(GetEntityMaxHealth(ped), health + (values.health or 0)))
    end
end)

RegisterNetEvent('thootje-inventory:client:itemUsed', function(item, metadata)
    TriggerEvent('thootje-inventory:client:useItem', item, metadata)
end)

RegisterNUICallback('close', function(_, cb)
    setOpen(false)
    cb({ ok = true })
end)
RegisterNUICallback('move', function(data, cb)
    TriggerServerEvent('thootje-inventory:server:move', data.from, data.to, data.amount)
    cb({ ok = true })
end)
RegisterNUICallback('use', function(data, cb)
    TriggerServerEvent('thootje-inventory:server:use', data.slot)
    cb({ ok = true })
end)
RegisterNUICallback('drop', function(data, cb)
    TriggerServerEvent('thootje-inventory:server:drop', data.slot, data.count)
    cb({ ok = true })
end)
RegisterNUICallback('give', function(data, cb)
    TriggerServerEvent('thootje-inventory:server:give', data.slot, data.target, data.count)
    cb({ ok = true })
end)
RegisterNUICallback('split', function(data, cb)
    TriggerServerEvent('thootje-inventory:server:split', data.slot, data.count, data.to)
    cb({ ok = true })
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then SetNuiFocus(false, false) end
end)
