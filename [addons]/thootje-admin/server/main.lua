local frozen={}
local returnPositions={}

local function isAdmin(src,super)
    if src==0 then return true end
    return IsPlayerAceAllowed(src,super and Config.SuperAdminAce or Config.AdminAce)
end

local function notify(src,msg,kind)
    TriggerClientEvent('thootje-admin:client:notify',src,msg,kind or 'info')
end

local function identifiers(src)
    local out={}
    for _,v in ipairs(GetPlayerIdentifiers(src)) do
        if v:sub(1,8)=='license:' or v:sub(1,9)=='license2:' or v:sub(1,8)=='fivem:' or v:sub(1,8)=='discord:' then
            out[#out+1]=v
        end
    end
    return out
end

local function licenseIdentifier(src)
    for _,v in ipairs(GetPlayerIdentifiers(src)) do
        if v:sub(1,8)=='license:' then return v end
    end
    return GetPlayerIdentifier(src,0)
end

local function playerList()
    local result={}
    for _,id in ipairs(GetPlayers()) do
        local src=tonumber(id)
        local ped=GetPlayerPed(src)
        local coords=ped and ped>0 and GetEntityCoords(ped) or vector3(0,0,0)
        result[#result+1]={
            id=src,name=GetPlayerName(src) or 'Onbekend',
            ping=GetPlayerPing(src) or 0,
            coords={x=math.floor(coords.x),y=math.floor(coords.y),z=math.floor(coords.z)}
        }
    end
    table.sort(result,function(a,b) return a.id<b.id end)
    return result
end

local function logAction(src,action,target,details)
    if not Config.LogActions then return end
    local actor=src==0 and 'CONSOLE' or (GetPlayerName(src) or tostring(src))
    local targetName=target and GetPlayerName(target) or '-'
    print(('[THOOTJE-ADMIN] %s (%s) -> %s | target=%s (%s) | %s'):format(actor,src,action,targetName,target or '-',details or ''))
end

local function sendMenu(src)
    if not isAdmin(src) then return notify(src,'Je hebt geen toegang tot het adminmenu.','error') end
    TriggerClientEvent('thootje-admin:client:open',src,{
        players=playerList(),
        super=IsPlayerAceAllowed(src,Config.SuperAdminAce),
        version='1.0.0'
    })
end

RegisterNetEvent('thootje-admin:server:open',function() sendMenu(source) end)
RegisterNetEvent('thootje-admin:server:refresh',function()
    local src=source
    if not isAdmin(src) then return end
    TriggerClientEvent('thootje-admin:client:updatePlayers',src,playerList())
end)

local function banPlayer(src,target,days,reason)
    if not isAdmin(src,true) then return notify(src,'Alleen superadmins kunnen spelers bannen.','error') end
    target=tonumber(target)
    if not target or not GetPlayerName(target) then return notify(src,'Speler niet gevonden.','error') end
    local license=licenseIdentifier(target)
    if not license then return notify(src,'Geen license identifier gevonden.','error') end
    days=math.max(0,math.min(tonumber(days) or Config.DefaultBanDays,Config.MaxBanDays))
    local expires=days==0 and nil or (os.time()+days*86400)
    reason=tostring(reason or 'Geen reden opgegeven'):sub(1,250)
    MySQL.insert.await('INSERT INTO thootje_admin_bans (license, player_name, reason, banned_by, expires_at) VALUES (?, ?, ?, ?, ?)',{
        license,GetPlayerName(target),reason,GetPlayerName(src) or 'Console',expires
    })
    logAction(src,'BAN',target,reason)
    DropPlayer(target,('Je bent verbannen.\nReden: %s\nDuur: %s'):format(reason,days==0 and 'Permanent' or (days..' dagen')))
end

RegisterNetEvent('thootje-admin:server:action',function(action,target,value)
    local src=source
    if not isAdmin(src) then return end
    target=tonumber(target)
    value=type(value)=='table' and value or {}
    local valid=Config.Actions[action]
    if not valid then return end
    local needsTarget=({kick=true,warn=true,ban=true,freeze=true,heal=true,revive=true,['goto']=true,bring=true,['return']=true,spectate=true})[action]
    if needsTarget and (not target or not GetPlayerName(target)) then return notify(src,'Selecteer een geldige speler.','error') end
    if action=='ban' or action=='unban' or action=='restartresource' or action=='setweather' or action=='settime' or action=='cleararea' then
        if not isAdmin(src,true) then return notify(src,'Deze actie vereist superadminrechten.','error') end
    end

    if action=='kick' then
        local reason=tostring(value.reason or 'Verwijderd door staff'):sub(1,200)
        logAction(src,'KICK',target,reason); DropPlayer(target,'Je bent gekickt.\nReden: '..reason)
    elseif action=='warn' then
        local reason=tostring(value.reason or 'Waarschuwing van staff'):sub(1,200)
        logAction(src,'WARN',target,reason); notify(target,'Staffwaarschuwing: '..reason,'error'); notify(src,'Waarschuwing verstuurd.','success')
    elseif action=='ban' then
        banPlayer(src,target,value.days,value.reason)
    elseif action=='freeze' then
        frozen[target]=not frozen[target]
        TriggerClientEvent('thootje-admin:client:freeze',target,frozen[target])
        logAction(src,'FREEZE',target,tostring(frozen[target]))
    elseif action=='heal' then
        TriggerClientEvent('thootje-admin:client:heal',target); logAction(src,'HEAL',target)
    elseif action=='revive' then
        TriggerClientEvent('thootje-admin:client:revive',target); logAction(src,'REVIVE',target)
    elseif action=='goto' then
        local ped=GetPlayerPed(target); if ped>0 then
            local c=GetEntityCoords(ped); local h=GetEntityHeading(ped)
            TriggerClientEvent('thootje-admin:client:saveReturn',src)
            TriggerClientEvent('thootje-admin:client:teleport',src,{x=c.x,y=c.y,z=c.z+1.0,w=h})
            logAction(src,'GOTO',target)
        end
    elseif action=='bring' then
        local ped=GetPlayerPed(src); local targetPed=GetPlayerPed(target)
        if ped>0 and targetPed>0 then
            local c=GetEntityCoords(ped); local h=GetEntityHeading(ped)
            TriggerClientEvent('thootje-admin:client:saveReturn',target)
            TriggerClientEvent('thootje-admin:client:teleport',target,{x=c.x,y=c.y,z=c.z+1.0,w=h})
            logAction(src,'BRING',target)
        end
    elseif action=='return' then
        TriggerClientEvent('thootje-admin:client:return',target); logAction(src,'RETURN',target)
    elseif action=='spectate' then
        TriggerClientEvent('thootje-admin:client:spectate',src,target); logAction(src,'SPECTATE',target)
    elseif action=='announce' then
        local msg=tostring(value.message or ''):sub(1,250)
        if msg=='' then return end
        TriggerClientEvent('thootje-admin:client:announce',-1,msg); logAction(src,'ANNOUNCE',nil,msg)
    elseif action=='spawnvehicle' then
        local model=tostring(value.model or ''):lower():gsub('[^%w_]','')
        if #model<2 or #model>40 then return notify(src,'Ongeldig voertuigmodel.','error') end
        TriggerClientEvent('thootje-admin:client:spawnVehicle',src,model); logAction(src,'SPAWNVEHICLE',src,model)
    elseif action=='setweather' then
        local weather=tostring(value.weather or 'CLEAR'):upper()
        local allowed={CLEAR=true,EXTRASUNNY=true,CLOUDS=true,OVERCAST=true,RAIN=true,THUNDER=true,FOGGY=true,SMOG=true,NEUTRAL=true,SNOW=true,BLIZZARD=true}
        if not allowed[weather] then return end
        TriggerClientEvent('thootje-admin:client:weather',-1,weather); logAction(src,'WEATHER',nil,weather)
    elseif action=='settime' then
        local hour=math.max(0,math.min(23,tonumber(value.hour) or 12))
        local minute=math.max(0,math.min(59,tonumber(value.minute) or 0))
        TriggerClientEvent('thootje-admin:client:time',-1,hour,minute); logAction(src,'TIME',nil,('%02d:%02d'):format(hour,minute))
    elseif action=='cleararea' then
        local radius=math.max(5,math.min(tonumber(value.radius) or 30,100))
        local ped=GetPlayerPed(src)
        if ped>0 then
            local c=GetEntityCoords(ped)
            for _,veh in ipairs(GetAllVehicles()) do
                local vc=GetEntityCoords(veh)
                if #(vc-c)<=radius and GetPedInVehicleSeat(veh,-1)==0 then DeleteEntity(veh) end
            end
            logAction(src,'CLEARAREA',nil,tostring(radius))
        end
    elseif action=='restartresource' then
        local resource=tostring(value.resource or ''):gsub('[^%w_%-]','')
        if resource=='' or resource==GetCurrentResourceName() then return notify(src,'Ongeldige resource.','error') end
        logAction(src,'RESTARTRESOURCE',nil,resource)
        notify(src,'Resource restart aangevraagd: '..resource)
        ExecuteCommand('restart '..resource)
    elseif action=='unban' then
        local license=tostring(value.license or '')
        if license=='' then return end
        local count=MySQL.update.await('DELETE FROM thootje_admin_bans WHERE license = ?', {license})
        notify(src,(count or 0)>0 and 'Ban verwijderd.' or 'Geen actieve ban gevonden.')
        logAction(src,'UNBAN',nil,license)
    end
end)

AddEventHandler('playerConnecting',function(playerName,setKickReason,deferrals)
    local src=source
    deferrals.defer()
    Wait(0)
    local license=licenseIdentifier(src)
    if not license then deferrals.done(); return end
    local ban=MySQL.single.await('SELECT * FROM thootje_admin_bans WHERE license = ? ORDER BY id DESC LIMIT 1',{license})
    if ban then
        if ban.expires_at and tonumber(ban.expires_at)<os.time() then
            MySQL.update.await('DELETE FROM thootje_admin_bans WHERE id = ?',{ban.id})
        else
            local expiry=ban.expires_at and os.date('%d-%m-%Y %H:%M',tonumber(ban.expires_at)) or 'Permanent'
            deferrals.done(('Je bent verbannen van deze server.\nReden: %s\nDoor: %s\nVerloopt: %s'):format(ban.reason,ban.banned_by,expiry))
            return
        end
    end
    deferrals.done()
end)

RegisterCommand('adminunban',function(src,args)
    if src~=0 and not isAdmin(src,true) then return end
    local license=args[1]
    if not license then if src>0 then notify(src,'Gebruik: /adminunban license:...') end return end
    MySQL.update.await('DELETE FROM thootje_admin_bans WHERE license = ?',{license})
    if src>0 then notify(src,'Unban uitgevoerd.') end
end,true)

RegisterCommand('adminannounce',function(src,args)
    if src~=0 and not isAdmin(src,true) then return end
    local msg=table.concat(args,' ')
    if msg~='' then TriggerClientEvent('thootje-admin:client:announce',-1,msg) end
end,true)

AddEventHandler('playerDropped',function() frozen[source]=nil end)
