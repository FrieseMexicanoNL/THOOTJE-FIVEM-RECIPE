local tablet=false
local lastOdo,lastPlate={},{}
local lockedPlates={}
local serviceDueNotified={}

local function plateClean(p) return (tostring(p or ''):upper():gsub('%s+','')) end
local function openTablet()
    if tablet then return end
    local data=lib.callback.await('thootje-pechhulp:server:getTabletData',false)
    if not data or not data.allowed then lib.notify({description='Alleen pechhulpmedewerkers in dienst kunnen de tablet openen.',type='error'}); return end
    tablet=true; SetNuiFocus(true,true); SendNUIMessage({action='open',data=data})
end
RegisterCommand(Config.TabletCommand,openTablet)
RegisterKeyMapping(Config.TabletCommand,'Open pechhulp-tablet','keyboard','F6')
RegisterNUICallback('close',function(_,cb) tablet=false; SetNuiFocus(false,false); cb(true) end)
RegisterNUICallback('accept',function(d,cb) TriggerServerEvent('thootje-pechhulp:server:acceptCall',d.id); cb(true) end)
RegisterNUICallback('closeCall',function(d,cb) TriggerServerEvent('thootje-pechhulp:server:closeCall',d.id); cb(true) end)
RegisterNUICallback('inspect',function(d,cb)
    local veh=GetVehiclePedIsIn(PlayerPedId(),false)
    if veh~=0 then d.model=GetDisplayNameFromVehicleModel(GetEntityModel(veh)); d.owner='' end
    TriggerServerEvent('thootje-pechhulp:server:recordInspection',d); cb(true)
end)
RegisterNUICallback('service',function(d,cb) TriggerServerEvent('thootje-pechhulp:server:service',d); cb(true) end)
RegisterNUICallback('invoice',function(d,cb) TriggerServerEvent('thootje-pechhulp:server:createInvoice',d); cb(true) end)
RegisterNUICallback('craft',function(d,cb) TriggerServerEvent('thootje-pechhulp:server:craft',d.item); cb(true) end)
RegisterNUICallback('vehicleInfo',function(d,cb)
    local result=lib.callback.await('thootje-pechhulp:server:vehicleInfo',false,d.plate)
    cb(result or {})
end)
RegisterNUICallback('diagnostic',function(d,cb)
    local veh=GetVehiclePedIsIn(PlayerPedId(),false)
    if veh==0 then veh=lib.getClosestVehicle(GetEntityCoords(PlayerPedId()),5.0,true) end
    if not veh or veh==0 then cb({ok=false}); return end
    local tyres=0
    for i=0,5 do if IsVehicleTyreBurst(veh,i,false) then tyres=tyres+1 end end
    local plate=plateClean(GetVehicleNumberPlateText(veh))
    TriggerServerEvent('thootje-pechhulp:server:diagnostic',{plate=plate,engine=GetVehicleEngineHealth(veh),body=GetVehicleBodyHealth(veh),fuel=GetVehicleFuelLevel(veh),tyres=tyres,battery=GetVehicleEngineHealth(veh)>500 and 100 or 35})
    cb({ok=true})
end)
RegisterNUICallback('recordService',function(d,cb) TriggerServerEvent('thootje-pechhulp:server:recordService',d); cb(true) end)

RegisterNetEvent('thootje-pechhulp:client:newCall',function(data)
    lib.notify({title='Nieuwe pechhulp-melding',description=(data.problem or 'Pech')..' | '..(data.plate or ''),type='inform'})
    if tablet then SendNUIMessage({action='newCall',data=data}) end
end)
RegisterNetEvent('thootje-pechhulp:client:callAccepted',function(data)
    lib.notify({title='Pechhulp onderweg',description='Je melding is aangenomen door '..(data.staff or 'een medewerker'),type='success'})
end)
RegisterNetEvent('thootje-pechhulp:client:invoiceReceived',function(data)
    lib.notify({title='Pechhulp-factuur',description=('Factuur #%s: €%s - %s'):format(data.id,data.amount,data.description),type='inform'})
end)
RegisterNetEvent('thootje-pechhulp:client:invoicePrompt',function(data)
    local input=lib.inputDialog('Factuur versturen',{{type='number',label='Server ID klant',required=true,min=1},{type='number',label='Bedrag (€)',default=data.amount,required=true,min=1},{type='input',label='Omschrijving',default=data.description,required=true}})
    if input then TriggerServerEvent('thootje-pechhulp:server:createInvoice',{target=input[1],amount=input[2],description=input[3]}) end
end)
RegisterNetEvent('thootje-pechhulp:client:diagnosticResult',function(d)
    lib.alertDialog({header='Voertuigdiagnose · '..d.plate,content=('Motor: %s/1000\\nCarrosserie: %s/1000\\nBrandstof: %s%%\\nLekke banden: %s\\nAdvies: %s'):format(d.engine,d.body,d.fuel,d.tyres,d.severity),centered=true})
end)
RegisterNetEvent('thootje-pechhulp:client:serviceDue',function(plate,mileage,nextService)
    if serviceDueNotified[plate] then return end
    serviceDueNotified[plate]=true
    lib.notify({title='Onderhoud nodig',description=('Voertuig %s heeft een kleine beurt nodig (%s km / interval %s km).'):format(plate,mileage,nextService),type='warning',duration=12000})
end)
RegisterNetEvent('thootje-pechhulp:client:setRoadworthy',function(plate,approved,reason)
    if approved then lockedPlates[plate]=nil else lockedPlates[plate]=reason or 'Voertuig afgekeurd' end
    local veh=GetVehiclePedIsIn(PlayerPedId(),false)
    if veh~=0 and plateClean(GetVehicleNumberPlateText(veh))==plate and not approved then
        SetVehicleEngineOn(veh,false,true,true); SetVehicleUndriveable(veh,true)
        lib.notify({title='Voertuig afgekeurd',description=reason or 'Dit voertuig mag niet rijden.',type='error'})
    end
end)
RegisterNetEvent('thootje-pechhulp:client:deleteVehicle',function(netId)
    local veh=NetToVeh(netId); if veh~=0 and DoesEntityExist(veh) then DeleteEntity(veh) end
end)

-- Odometer: accumulate real world distance while driving. Server validates every update.
CreateThread(function()
    while true do
        Wait(Config.Mileage.UpdateIntervalMs)
        local ped=PlayerPedId()
        local veh=GetVehiclePedIsIn(ped,false)
        if veh~=0 and GetPedInVehicleSeat(veh,-1)==ped then
            local plate=plateClean(GetVehicleNumberPlateText(veh))
            local coords=GetEntityCoords(veh)
            local previous=lastOdo[plate]
            if previous then
                local dist=#(coords-previous)
                if dist>=Config.Mileage.MinDistanceMeters and dist<=Config.Mileage.MaxDistancePerUpdate then
                    TriggerServerEvent('thootje-pechhulp:server:updateMileage',{plate=plate,distance=dist,model=GetDisplayNameFromVehicleModel(GetEntityModel(veh))})
                end
            end
            lastOdo[plate]=coords
        else
            lastOdo={}
        end
    end
end)

-- Block driving when the registered vehicle has an expired APK, was disapproved or scrapped.
CreateThread(function()
    while true do
        Wait(Config.VehicleEnforcement.CheckIntervalMs)
        local ped=PlayerPedId()
        local veh=GetVehiclePedIsIn(ped,false)
        if veh~=0 and GetPedInVehicleSeat(veh,-1)==ped then
            local plate=plateClean(GetVehicleNumberPlateText(veh))
            local result=lib.callback.await('thootje-pechhulp:server:checkVehicle',false,plate)
            if result and not result.allowed then
                SetVehicleEngineOn(veh,false,true,true); SetVehicleUndriveable(veh,true)
                local reason=result.expired and 'APK verlopen' or 'Voertuig afgekeurd'
                if not lockedPlates[plate] then
                    lockedPlates[plate]=reason
                    lib.notify({title='Voertuig niet rijwaardig',description=reason..'. Neem contact op met de pechhulp.',type='error'})
                end
            elseif result and result.allowed and lockedPlates[plate] then
                lockedPlates[plate]=nil; SetVehicleUndriveable(veh,false)
            end
        end
    end
end)

RegisterCommand('pechhulp',function()
    local ped=PlayerPedId(); local coords=GetEntityCoords(ped)
    local veh=GetVehiclePedIsIn(ped,false)
    local plate=veh~=0 and GetVehicleNumberPlateText(veh) or ''
    local input=lib.inputDialog('Pechhulp bellen',{{type='select',label='Probleem',required=true,options={{value='Accu leeg',label='Accu leeg'},{value='Geen brandstof',label='Geen brandstof'},{value='Motorstoring',label='Motorstoring'},{value='Lekke band',label='Lekke band'},{value='Schade / ongeval',label='Schade / ongeval'},{value='Voertuig start niet',label='Voertuig start niet'},{value='Anders',label='Anders'}}},{type='input',label='Extra informatie',required=false},{type='input',label='Kenteken',default=plate,required=false},{type='input',label='Telefoonnummer',required=false}})
    if input then TriggerServerEvent('thootje-pechhulp:server:call',{problem=input[1],details=input[2],plate=input[3],phone=input[4],coords={x=coords.x,y=coords.y,z=coords.z}}) end
end)
RegisterCommand('pechhulpabonnement',function()
    local input=lib.inputDialog('Pechhulp-abonnement',{{type='select',label='Kies abonnement',options={{value='basic',label='Pechhulp Abonnement - €2.500 / 30 dagen'},{value='plus',label='Pechhulp+ - €5.000 / 30 dagen'}}}})
    if input then TriggerServerEvent('thootje-pechhulp:server:subscribe',input[1]) end
end)
