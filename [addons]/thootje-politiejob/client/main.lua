local cuffed=false
local escortedBy=nil
local mdtOpen=false
local function notify(m,k) TriggerEvent(Config.NotifyEvent,m,k or 'info') end
local function loadAnim(dict)
 RequestAnimDict(dict); local t=0
 while not HasAnimDictLoaded(dict) and t<5000 do Wait(10); t=t+10 end
 return HasAnimDictLoaded(dict)
end
local function nearestPlayer(maxDist)
 local me=PlayerId(); local my=GetEntityCoords(PlayerPedId()); local best,dist=nil,maxDist
 for _,p in ipairs(GetActivePlayers()) do
  if p~=me then local d=#(GetEntityCoords(GetPlayerPed(p))-my); if d<dist then best=p; dist=d end end
 end
 return best and GetPlayerServerId(best) or nil
end
RegisterCommand(Config.OpenCommand,function() TriggerServerEvent('thootje-politiejob:server:openMenu') end,false)
RegisterCommand(Config.MDTCommand,function() TriggerServerEvent('thootje-politiejob:server:openMDT') end,false)
RegisterKeyMapping(Config.MDTCommand,'Open politie MDT','keyboard',Config.MDTKey)
RegisterCommand('cuff',function() local t=nearestPlayer(Config.CuffDistance); if t then TriggerServerEvent('thootje-politiejob:server:cuff',t) else notify(Config.Locale.noTarget,'error') end end,false)
RegisterCommand('escort',function() local t=nearestPlayer(Config.EscortDistance); if t then TriggerServerEvent('thootje-politiejob:server:escort',t) else notify(Config.Locale.noTarget,'error') end end,false)
RegisterCommand('search',function() local t=nearestPlayer(Config.SearchDistance); if t then TriggerServerEvent('thootje-politiejob:server:search',t) else notify(Config.Locale.noTarget,'error') end end,false)
RegisterCommand('panic',function() TriggerServerEvent('thootje-politiejob:server:panic') end,false)
RegisterCommand('pdarmory',function() TriggerServerEvent('thootje-politiejob:server:requestArmory') end,false)
RegisterCommand('pdgarage',function() TriggerServerEvent('thootje-politiejob:server:requestGarage') end,false)
RegisterCommand('fine',function(_,a) local t=tonumber(a[1]);local n=tonumber(a[2]);local r=table.concat(a,' ',3);if t and n and r~='' then TriggerServerEvent('thootje-politiejob:server:fine',{target=t,amount=n,reason=r}) end end,false)
RegisterCommand('jail',function(_,a) local t=tonumber(a[1]);local m=tonumber(a[2]);if t and m then TriggerServerEvent('thootje-politiejob:server:jail',t,m) end end,false)
RegisterCommand('unjail',function(_,a) if tonumber(a[1]) then TriggerServerEvent('thootje-politiejob:server:unjail',tonumber(a[1])) end end,false)

RegisterNetEvent('thootje-politiejob:client:openMDT',function(data)
 mdtOpen=true;SetNuiFocus(true,true);SendNUIMessage({action='open',data=data})
end)
RegisterNetEvent('thootje-politiejob:client:updateMDT',function(data) SendNUIMessage({action='update',data=data}) end)
RegisterNetEvent('thootje-politiejob:client:notify',function(m,k) notify(m,k) end)
RegisterNUICallback('close',function(_,cb) mdtOpen=false;SetNuiFocus(false,false);cb({ok=true}) end)
RegisterNUICallback('searchPlayer',function(d,cb) TriggerServerEvent('thootje-politiejob:server:searchPlayer',d.query);cb({ok=true}) end)
RegisterNUICallback('inspectPlayer',function(d,cb) TriggerServerEvent('thootje-politiejob:server:search',d.target);cb({ok=true}) end)
RegisterNUICallback('confiscateItem',function(d,cb) TriggerServerEvent('thootje-politiejob:server:confiscateItem',d.target,d.name,d.amount);cb({ok=true}) end)
RegisterNUICallback('createReport',function(d,cb) TriggerServerEvent('thootje-politiejob:server:createReport',d);cb({ok=true}) end)
RegisterNUICallback('fine',function(d,cb) TriggerServerEvent('thootje-politiejob:server:fine',d);cb({ok=true}) end)
RegisterNUICallback('refresh',function(_,cb) TriggerServerEvent('thootje-politiejob:server:openMDT');cb({ok=true}) end)
RegisterNetEvent('thootje-politiejob:client:searchResults',function(results) SendNUIMessage({action='searchResults',results=results}) end)
RegisterNetEvent('thootje-politiejob:client:showInventory',function(target,targetName,items) SendNUIMessage({action='showInventory',target=target,targetName=targetName,items=items or {}}) end)

RegisterNetEvent('thootje-politiejob:client:playCuff',function()
 if loadAnim(Config.Animations.cuffDict) then TaskPlayAnim(PlayerPedId(),Config.Animations.cuffDict,Config.Animations.cuffAnim,8.0,-8.0,1800,48,0,false,false,false) end
end)
RegisterNetEvent('thootje-politiejob:client:cuff',function(state)
 cuffed=state;local ped=PlayerPedId()
 if state then
  ClearPedTasks(ped);SetEnableHandcuffs(ped,true);SetCurrentPedWeapon(ped,`WEAPON_UNARMED`,true)
  if loadAnim(Config.Animations.cuffedDict) then TaskPlayAnim(ped,Config.Animations.cuffedDict,Config.Animations.cuffedAnim,8.0,-8.0,-1,49,0,false,false,false) end
  notify(Config.Locale.cuffed,'error')
 else ClearPedTasks(ped);SetEnableHandcuffs(ped,false);notify(Config.Locale.uncuffed,'success') end
end)
RegisterNetEvent('thootje-politiejob:client:escort',function(id)
 escortedBy=id
 if not id then DetachEntity(PlayerPedId(),true,false) end
end)
RegisterNetEvent('thootje-politiejob:client:playFrisk',function()
 if loadAnim(Config.Animations.searchDict) then TaskPlayAnim(PlayerPedId(),Config.Animations.searchDict,Config.Animations.searchAnim,8.0,-8.0,2200,49,0,false,false,false) end
end)
RegisterNetEvent('thootje-politiejob:client:jail',function(coords,minutes)
 local ped=PlayerPedId();SetEntityCoords(ped,coords.x,coords.y,coords.z);SetEntityHeading(ped,coords.w);notify(('Je bent opgesloten voor %s minuten.'):format(minutes),'error')
end)
RegisterNetEvent('thootje-politiejob:client:jailTime',function(minutes) SendNUIMessage({action='jailTime',minutes=minutes}) end)
RegisterNetEvent('thootje-politiejob:client:release',function(coords)
 local ped=PlayerPedId();SetEntityCoords(ped,coords.x,coords.y,coords.z);SetEntityHeading(ped,coords.w);notify(Config.Locale.released,'success')
end)
RegisterNetEvent('thootje-politiejob:client:armory',function(items)
 local list={};for i,v in ipairs(items) do list[#list+1]=i..'. '..v.label end
 notify('Wapenuitgifte: '..table.concat(list,' | ')..' — gebruik /pdweapon [nummer].','info')
end)
RegisterCommand('pdweapon',function(_,a)
 local idx=tonumber(a[1]) or 1;TriggerServerEvent('thootje-politiejob:server:giveWeapon',idx)
end,false)
RegisterNetEvent('thootje-politiejob:client:giveWeapon',function(weapon,label)
 GiveWeaponToPed(PlayerPedId(),joaat(weapon),60,false,true);notify(label..' uitgegeven.','success')
end)
RegisterNetEvent('thootje-politiejob:client:garage',function(vehicles)
 local labels={};for i,v in ipairs(vehicles) do labels[#labels+1]=i..'. '..v.label..' (/pdvehicle '..i..')' end
 notify('Dienstgarage: '..table.concat(labels,' | '),'info')
end)
RegisterCommand('pdvehicle',function(_,a) TriggerServerEvent('thootje-politiejob:server:spawnVehicle',tonumber(a[1]) or 1) end,false)
RegisterNetEvent('thootje-politiejob:client:spawnVehicle',function(model)
 local hash=joaat(model);if not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then notify('Onbekend voertuigmodel.','error');return end
 RequestModel(hash);local t=0;while not HasModelLoaded(hash) and t<7000 do Wait(10);t=t+10 end
 if not HasModelLoaded(hash) then notify('Voertuig laden mislukt.','error');return end
 local p=PlayerPedId();local c=GetEntityCoords(p);local v=CreateVehicle(hash,c.x+3,c.y,c.z,GetEntityHeading(p),true,false)
 SetVehicleNumberPlateText(v,('PD%04d'):format(GetPlayerServerId(PlayerId())%10000));SetVehicleEngineOn(v,true,true,false);TaskWarpPedIntoVehicle(p,v,-1);SetModelAsNoLongerNeeded(hash)
end)

CreateThread(function()
 if Config.Blips.enabled then
  local b=AddBlipForCoord(Config.Blips.coords.x,Config.Blips.coords.y,Config.Blips.coords.z)
  SetBlipSprite(b,Config.Blips.sprite);SetBlipColour(b,Config.Blips.color);SetBlipScale(b,Config.Blips.scale);SetBlipAsShortRange(b,true)
  BeginTextCommandSetBlipName('STRING');AddTextComponentString(Config.Blips.label);EndTextCommandSetBlipName(b)
 end
 while true do
  local wait=1000;local ped=PlayerPedId()
  if cuffed then
   wait=0
   for _,control in ipairs({21,22,24,25,37,44,75,140,141,257,263,264}) do DisableControlAction(0,control,true) end
   if not IsEntityPlayingAnim(ped,Config.Animations.cuffedDict,Config.Animations.cuffedAnim,3) and loadAnim(Config.Animations.cuffedDict) then
    TaskPlayAnim(ped,Config.Animations.cuffedDict,Config.Animations.cuffedAnim,8.0,-8.0,-1,49,0,false,false,false)
   end
  end
  if escortedBy then
   wait=0;local player=GetPlayerFromServerId(escortedBy)
   if player~=-1 then local cop=GetPlayerPed(player);if DoesEntityExist(cop) and not IsEntityAttachedToEntity(ped,cop) then AttachEntityToEntity(ped,cop,11816,0.45,0.45,0,0,0,0,false,false,false,false,2,true) end end
  end
  if mdtOpen and IsControlJustReleased(0,200) then mdtOpen=false;SetNuiFocus(false,false);SendNUIMessage({action='close'}) end
  Wait(wait)
 end
end)
