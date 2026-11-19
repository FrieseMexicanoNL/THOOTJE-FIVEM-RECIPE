Thootje = { PlayerData = {}, Callbacks = {}, RequestId = 0 }

function Thootje.GetPlayerData()
    return Thootje.PlayerData
end

function Thootje.TriggerServerCallback(name, cb, ...)
    Thootje.RequestId = Thootje.RequestId + 1
    local id = Thootje.RequestId
    Thootje.Callbacks[id] = cb
    TriggerServerEvent('thootje:server:triggerCallback', name, id, ...)
end

RegisterNetEvent('thootje:client:callbackResponse', function(id, ...)
    local cb = Thootje.Callbacks[id]
    if cb then cb(...) Thootje.Callbacks[id] = nil end
end)

RegisterNetEvent('thootje:client:playerLoaded', function(data)
    Thootje.PlayerData = data or {}
    SendNUIMessage({ action = 'player', data = Thootje.PlayerData })
    TriggerEvent('thootje:client:ready', Thootje.PlayerData)
end)

RegisterNetEvent('thootje:client:updateData', function(data)
    Thootje.PlayerData = data or {}
    SendNUIMessage({ action = 'player', data = Thootje.PlayerData })
end)

RegisterNetEvent('thootje:client:openInventory', function(items)
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'inventory', items = items or {}, visible = true })
end)

RegisterNUICallback('close', function(_, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    cb('ok')
end)

RegisterCommand('thootjehud', function()
    SendNUIMessage({ action = 'toggleHud' })
end, false)

RegisterCommand('inv', function()
    TriggerServerEvent('thootje:server:requestInventory')
end, false)
RegisterKeyMapping('inv', 'Open Thootje inventory', 'keyboard', 'F2')
