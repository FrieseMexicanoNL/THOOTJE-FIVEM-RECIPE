local menuOpen=false
local lastPosition=nil
local spectating=false
local spectateTarget=nil

local function notify(msg,kind)
    TriggerEvent(Config.NotifyEvent, kind or 'info', msg)
end

RegisterCommand(Config.OpenCommand,function()
    TriggerServerEvent('thootje-admin:server:open')
end)
RegisterKeyMapping(Config.OpenCommand,'Open THOOTJE Adminmenu','keyboard',Config.OpenKey)

RegisterNetEvent('thootje-admin:client:open',function(data)
    menuOpen=true
    SetNuiFocus(true,true)
    SendNUIMessage({action='open',data=data})
end)

RegisterNetEvent('thootje-admin:client:updatePlayers',function(players)
    SendNUIMessage({action='players',players=players})
end)

RegisterNetEvent('thootje-admin:client:close',function()
    menuOpen=false
    SetNuiFocus(false,false)
    SendNUIMessage({action='close'})
end)

RegisterNUICallback('close',function(_,cb)
    menuOpen=false
    SetNuiFocus(false,false)
    cb({ok=true})
end)

RegisterNUICallback('refresh',function(_,cb)
    TriggerServerEvent('thootje-admin:server:refresh')
    cb({ok=true})
end)

RegisterNUICallback('action',function(data,cb)
    TriggerServerEvent('thootje-admin:server:action',data.action,data.target,data.value or {})
    cb({ok=true})
end)

RegisterNetEvent('thootje-admin:client:notify',function(message,kind)
    notify(message,kind)
end)

RegisterNetEvent('thootje-admin:client:freeze',function(state)
    FreezeEntityPosition(PlayerPedId(),state==true)
    notify(state and 'Je bent bevroren door een administrator.' or 'Je bent niet langer bevroren.')
end)

RegisterNetEvent('thootje-admin:client:heal',function()
    local ped=PlayerPedId()
    SetEntityHealth(ped,GetEntityMaxHealth(ped))
    ClearPedBloodDamage(ped)
    ResetPedVisibleDamage(ped)
    ClearPedLastWeaponDamage(ped)
end)

RegisterNetEvent('thootje-admin:client:revive',function()
    local ped=PlayerPedId()
    local coords=GetEntityCoords(ped)
    NetworkResurrectLocalPlayer(coords.x,coords.y,coords.z,GetEntityHeading(ped),true,false)
    SetEntityHealth(PlayerPedId(),200)
    ClearPedBloodDamage(PlayerPedId())
end)

RegisterNetEvent('thootje-admin:client:teleport',function(coords)
    SetEntityCoords(PlayerPedId(),coords.x,coords.y,coords.z,false,false,false,false)
    if coords.w then SetEntityHeading(PlayerPedId(),coords.w) end
end)

RegisterNetEvent('thootje-admin:client:saveReturn',function()
    local c=GetEntityCoords(PlayerPedId())
    lastPosition={x=c.x,y=c.y,z=c.z,w=GetEntityHeading(PlayerPedId())}
end)

RegisterNetEvent('thootje-admin:client:return',function()
    if not lastPosition then return notify('Geen vorige positie opgeslagen.','error') end
    SetEntityCoords(PlayerPedId(),lastPosition.x,lastPosition.y,lastPosition.z,false,false,false,false)
    SetEntityHeading(PlayerPedId(),lastPosition.w or 0.0)
    lastPosition=nil
end)

RegisterNetEvent('thootje-admin:client:spectate',function(serverId)
    local target=GetPlayerFromServerId(serverId)
    if target==-1 then return notify('Speler niet gevonden.','error') end
    if spectating then
        NetworkSetInSpectatorMode(false,PlayerPedId())
        spectating=false
        spectateTarget=nil
    else
        local ped=GetPlayerPed(target)
        if not DoesEntityExist(ped) then return end
        spectateTarget=serverId
        spectating=true
        NetworkSetInSpectatorMode(true,ped)
    end
end)

RegisterNetEvent('thootje-admin:client:spawnVehicle',function(model)
    local hash=joaat(model)
    if not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then return notify('Ongeldig voertuigmodel.','error') end
    RequestModel(hash)
    local timeout=GetGameTimer()+10000
    while not HasModelLoaded(hash) and GetGameTimer()<timeout do Wait(50) end
    if not HasModelLoaded(hash) then return notify('Voertuig kon niet worden geladen.','error') end
    local ped=PlayerPedId()
    local c=GetOffsetFromEntityInWorldCoords(ped,0.0,4.0,0.0)
    local veh=CreateVehicle(hash,c.x,c.y,c.z,GetEntityHeading(ped),true,false)
    SetPedIntoVehicle(ped,veh,-1)
    SetVehicleOnGroundProperly(veh)
    SetModelAsNoLongerNeeded(hash)
end)

RegisterNetEvent('thootje-admin:client:announce',function(message)
    SendNUIMessage({action='announcement',message=message})
end)

RegisterNetEvent('thootje-admin:client:weather',function(weather)
    SetWeatherTypeOvertimePersist(weather,3.0)
end)
RegisterNetEvent('thootje-admin:client:time',function(hour,minute)
    NetworkOverrideClockTime(hour,minute or 0,0)
end)

AddEventHandler('onResourceStop',function(resource)
    if resource==GetCurrentResourceName() then SetNuiFocus(false,false) end
end)

CreateThread(function()
    while true do
        if spectating and spectateTarget then
            local target=GetPlayerFromServerId(spectateTarget)
            if target==-1 or not NetworkIsPlayerActive(target) then
                NetworkSetInSpectatorMode(false,PlayerPedId())
                spectating=false
                spectateTarget=nil
            end
            Wait(1000)
        else Wait(2000) end
    end
end)
