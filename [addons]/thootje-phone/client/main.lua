local phoneOpen = false
local currentCall = nil
local function notify(message, kind)
    TriggerEvent(Config.NotifyEvent, kind or 'info', message)
end

local function openPhone()
    if phoneOpen then return end
    TriggerServerEvent('thootje-phone:server:open')
end

RegisterCommand(Config.OpenCommand, openPhone)
RegisterKeyMapping(Config.OpenCommand, 'Open THOOTJE telefoon', 'keyboard', Config.OpenKey)

RegisterNetEvent('thootje-phone:client:open', function(data)
    phoneOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', data = data })
end)

RegisterNetEvent('thootje-phone:client:data', function(data)
    SendNUIMessage({ action = 'data', data = data })
end)

RegisterNetEvent('thootje-phone:client:notify', notify)

RegisterNUICallback('close', function(_, cb)
    phoneOpen = false
    SetNuiFocus(false, false)
    cb({ ok = true })
end)
RegisterNUICallback('refresh', function(_, cb)
    TriggerServerEvent('thootje-phone:server:refresh')
    cb({ ok = true })
end)
RegisterNUICallback('addContact', function(data, cb)
    TriggerServerEvent('thootje-phone:server:addContact', data.name, data.number)
    cb({ ok = true })
end)
RegisterNUICallback('deleteContact', function(data, cb)
    TriggerServerEvent('thootje-phone:server:deleteContact', data.id)
    cb({ ok = true })
end)
RegisterNUICallback('sendMessage', function(data, cb)
    TriggerServerEvent('thootje-phone:server:sendMessage', data.number, data.message)
    cb({ ok = true })
end)
RegisterNUICallback('startCall', function(data, cb)
    TriggerServerEvent('thootje-phone:server:startCall', data.number)
    cb({ ok = true })
end)
RegisterNUICallback('answerCall', function(data, cb)
    TriggerServerEvent('thootje-phone:server:answerCall', data.callId)
    cb({ ok = true })
end)
RegisterNUICallback('declineCall', function(data, cb)
    TriggerServerEvent('thootje-phone:server:declineCall', data.callId)
    cb({ ok = true })
end)
RegisterNUICallback('hangup', function(_, cb)
    TriggerServerEvent('thootje-phone:server:hangup')
    cb({ ok = true })
end)
RegisterNUICallback('wallpaper', function(data, cb)
    TriggerServerEvent('thootje-phone:server:saveWallpaper', data.wallpaper)
    cb({ ok = true })
end)
RegisterNUICallback('saveNote', function(data, cb)
    TriggerServerEvent('thootje-phone:server:saveNote', data.id, data.title, data.body)
    cb({ ok = true })
end)
RegisterNUICallback('deleteNote', function(data, cb)
    TriggerServerEvent('thootje-phone:server:deleteNote', data.id)
    cb({ ok = true })
end)

RegisterNetEvent('thootje-phone:client:newMessage', function(data)
    SendNUIMessage({ action = 'newMessage', data = data })
end)
RegisterNetEvent('thootje-phone:client:incomingCall', function(data)
    currentCall = data.callId
    SendNUIMessage({ action = 'incomingCall', data = data })
    if not phoneOpen then openPhone() end
end)
RegisterNetEvent('thootje-phone:client:outgoingCall', function(data)
    currentCall = data.callId
    SendNUIMessage({ action = 'outgoingCall', data = data })
end)
RegisterNetEvent('thootje-phone:client:callConnected', function(data)
    if Config.CallVoiceMode == 'pma-voice' and GetResourceState('pma-voice') == 'started' then
        exports['pma-voice']:setCallChannel(data.channel)
    end
    SendNUIMessage({ action = 'callConnected', data = data })
end)
RegisterNetEvent('thootje-phone:client:callEnded', function(message)
    if Config.CallVoiceMode == 'pma-voice' and GetResourceState('pma-voice') == 'started' then
        exports['pma-voice']:setCallChannel(0)
    end
    currentCall = nil
    SendNUIMessage({ action = 'callEnded', message = message })
    notify(message)
end)
RegisterNetEvent('thootje-phone:client:wallpaper', function(wallpaper)
    SendNUIMessage({ action = 'wallpaper', wallpaper = wallpaper })
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        SetNuiFocus(false, false)
        if currentCall then TriggerServerEvent('thootje-phone:server:hangup') end
    end
end)
