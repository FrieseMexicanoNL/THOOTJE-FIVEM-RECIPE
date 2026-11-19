local isOpen = false
local function setOpen(state)
    isOpen = state
    SetNuiFocus(state, state)
    SendNUIMessage({ action = state and 'show' or 'hide' })
    if state then TriggerServerEvent('thootje-banking:server:requestData') end
end

RegisterCommand(Config.Commands.Bank, function() setOpen(not isOpen) end, false)
RegisterCommand(Config.Commands.ATM, function() setOpen(not isOpen) end, false)
RegisterKeyMapping(Config.Commands.Bank, 'Open THOOTJE Bankieren', 'keyboard', Config.Keybind)

RegisterNetEvent('thootje-banking:client:openData', function(data)
    if not isOpen then
        isOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({ action = 'show' })
    end
    SendNUIMessage({ action = 'data', payload = data })
end)

RegisterNetEvent('thootje-banking:client:refreshBalance', function(account, history)
    SendNUIMessage({ action = 'refresh', account = account, history = history })
end)

RegisterNetEvent('thootje-banking:client:notify', function(message, kind)
    SendNUIMessage({ action = 'toast', message = message, kind = kind })
end)

RegisterNUICallback('close', function(_, cb)
    setOpen(false)
    cb('ok')
end)

RegisterNUICallback('transfer', function(data, cb)
    TriggerServerEvent('thootje-banking:server:transfer', data.accountNumber, data.amount, data.description)
    cb('ok')
end)

RegisterNUICallback('rename', function(data, cb)
    TriggerServerEvent('thootje-banking:server:renameAccount', data.name)
    cb('ok')
end)

CreateThread(function()
    while true do
        if isOpen then
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 200, true)
            Wait(0)
        else
            Wait(500)
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then SetNuiFocus(false, false) end
end)
