local opened=false
local function openBilling()
    if opened then return end
    TriggerServerEvent('thootje-billing:server:requestData')
end

RegisterCommand(Config.Command, openBilling, false)
RegisterKeyMapping(Config.Command,'Open facturenmenu','keyboard',Config.Key)

RegisterNetEvent('thootje-billing:client:open',function(data)
    opened=true
    SetNuiFocus(true,true)
    SendNUIMessage({action='open',data=data})
end)

RegisterNetEvent('thootje-billing:client:update',function(data)
    SendNUIMessage({action='update',data=data})
end)

RegisterNetEvent('thootje-billing:client:notify',function(message,kind)
    TriggerEvent(Config.NotifyEvent,message,kind or 'info')
end)

RegisterNUICallback('close',function(_,cb)
    opened=false
    SetNuiFocus(false,false)
    cb({ok=true})
end)

RegisterNUICallback('create',function(data,cb)
    TriggerServerEvent('thootje-billing:server:create',data)
    cb({ok=true})
end)
RegisterNUICallback('pay',function(data,cb)
    TriggerServerEvent('thootje-billing:server:pay',tonumber(data.id))
    cb({ok=true})
end)
RegisterNUICallback('reject',function(data,cb)
    TriggerServerEvent('thootje-billing:server:reject',tonumber(data.id))
    cb({ok=true})
end)
RegisterNUICallback('refresh',function(_,cb)
    TriggerServerEvent('thootje-billing:server:requestData')
    cb({ok=true})
end)

CreateThread(function()
    while true do
        Wait(0)
        if opened and IsControlJustReleased(0,200) then
            opened=false; SetNuiFocus(false,false); SendNUIMessage({action='close'})
        end
    end
end)
