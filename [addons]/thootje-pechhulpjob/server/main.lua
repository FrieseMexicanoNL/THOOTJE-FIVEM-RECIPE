local function ident(src) return THOOTJE_PCH.Identifier(src) end
local function staff(src) return THOOTJE_PCH.IsStaff(src) end
local function notify(src,msg,typ) THOOTJE_PCH.Notify(src,msg,typ) end
local function plateClean(p) return (tostring(p or ''):upper():gsub('%s+','')) end

local function subscription(identifier)
    if not identifier then return nil end
    return MySQL.single.await('SELECT * FROM thootje_pch_subscriptions WHERE owner_identifier=? AND expires_at > NOW() ORDER BY plan DESC LIMIT 1',{identifier})
end
local function discount(identifier, kind)
    local sub=subscription(identifier)
    if not sub or not Config.RequireSubscriptionForDiscount then return 0 end
    local plan=Config.SubscriptionPlans[sub.plan]
    if not plan then return 0 end
    if kind=='tow' then return plan.towDiscount or 0 end
    if kind=='kit' then return plan.repairkitDiscount or 0 end
    return plan.discount or 0
end
local function publishRoadworthy(plate, approved, reason)
    TriggerClientEvent('thootje-pechhulp:client:setRoadworthy',-1,plate,approved,reason)
end

lib.callback.register('thootje-pechhulp:server:getTabletData',function(src)
    local isStaff,grade,duty=staff(src)
    if not isStaff then return {allowed=false} end
    local open=MySQL.query.await("SELECT * FROM thootje_pch_calls WHERE status IN ('open','accepted') ORDER BY created_at DESC LIMIT 80")
    local history=MySQL.query.await('SELECT * FROM thootje_pch_maintenance ORDER BY created_at DESC LIMIT 50')
    local invoices=MySQL.query.await('SELECT * FROM thootje_pch_invoices ORDER BY created_at DESC LIMIT 50')
    return {allowed=true,grade=grade,calls=open,history=history,invoices=invoices}
end)

RegisterNetEvent('thootje-pechhulp:server:call',function(data)
    local src=source
    if type(data)~='table' then return end
    local id=ident(src); if not id then return end
    local problem=tostring(data.problem or 'Onbekend'):sub(1,120)
    local coords=data.coords or {}
    local x,y,z=tonumber(coords.x),tonumber(coords.y),tonumber(coords.z)
    if not x or not y or not z then return end
    local plate=plateClean(data.plate)
    local result=MySQL.insert.await('INSERT INTO thootje_pch_calls (caller_identifier,caller_name,phone,plate,problem,details,x,y,z,status) VALUES (?,?,?,?,?,?,?,?,?,?)',
      {id,GetPlayerName(src) or 'Onbekend',tostring(data.phone or ''):sub(1,30),plate,problem,tostring(data.details or ''):sub(1,500),x,y,z,'open'})
    TriggerClientEvent('thootje-pechhulp:client:newCall',-1,{id=result,name=GetPlayerName(src),problem=problem,plate=plate,details=data.details,coords={x=x,y=y,z=z}})
    notify(src,'Je pechhulp-melding is verstuurd. Blijf veilig staan.','success')
end)

RegisterNetEvent('thootje-pechhulp:server:acceptCall',function(id)
    local src=source; if not staff(src) then return end
    id=tonumber(id); if not id then return end
    local changed=MySQL.update.await("UPDATE thootje_pch_calls SET status='accepted',staff_identifier=?,staff_name=? WHERE id=? AND status='open'",{ident(src),GetPlayerName(src),id})
    if changed>0 then
        local row=MySQL.single.await('SELECT caller_identifier FROM thootje_pch_calls WHERE id=?',{id})
        for _,player in ipairs(GetPlayers()) do
            if ident(tonumber(player)) == (row and row.caller_identifier) then
                TriggerClientEvent('thootje-pechhulp:client:callAccepted',tonumber(player),{id=id,staff=GetPlayerName(src)})
                break
            end
        end
        notify(src,'Melding aangenomen.','success')
    else notify(src,'Deze melding is al aangenomen of gesloten.','error') end
end)

RegisterNetEvent('thootje-pechhulp:server:closeCall',function(id)
    local src=source; if not staff(src) then return end
    id=tonumber(id); if not id then return end
    MySQL.update.await("UPDATE thootje_pch_calls SET status='closed',closed_at=NOW() WHERE id=? AND status IN ('open','accepted')",{id})
    notify(src,'Melding afgesloten.','success')
end)

lib.callback.register('thootje-pechhulp:server:vehicleInfo',function(src,plate)
    if not staff(src) then return nil end
    plate=plateClean(plate)
    local row=MySQL.single.await('SELECT * FROM thootje_pch_vehicles WHERE plate=?',{plate})
    local history=MySQL.query.await('SELECT * FROM thootje_pch_maintenance WHERE plate=? ORDER BY created_at DESC LIMIT 20',{plate})
    return {vehicle=row,history=history,subscription=row and subscription(row.owner_identifier) or nil}
end)

-- Odometer updates: server validates driver, plate and plausible distance; applies to civilian and government vehicles.
RegisterNetEvent('thootje-pechhulp:server:updateMileage',function(data)
    if not Config.Mileage.Enabled or type(data)~='table' then return end
    local src=source
    local ped=GetPlayerPed(src); if ped==0 then return end
    local veh=GetVehiclePedIsIn(ped,false); if veh==0 or GetPedInVehicleSeat(veh,-1)~=ped then return end
    local plate=plateClean(data.plate)
    if plate=='' or plateClean(GetVehicleNumberPlateText(veh))~=plate then return end
    local distance=tonumber(data.distance) or 0
    if distance<Config.Mileage.MinDistanceMeters or distance>Config.Mileage.MaxDistancePerUpdate then return end
    local km=math.max(0,math.floor(distance/1000*10+0.5)/10)
    if km<=0 then return end
    local owner=ident(src) or 'unknown'
    local model=tostring(data.model or 'Onbekend'):sub(1,80)
    MySQL.insert.await([[
      INSERT INTO thootje_pch_vehicles (plate,owner_identifier,model,mileage,last_service_km,next_service_km,apk_expires,roadworthy,scrapped)
      VALUES (?,?,?,?,0,?,DATE_ADD(NOW(),INTERVAL ? DAY),1,0)
      ON DUPLICATE KEY UPDATE mileage=mileage+VALUES(mileage),model=IF(model IS NULL OR model='',VALUES(model),model)
    ]],{plate,owner,model,km,Config.Inspection.ServiceIntervalKm,Config.VehicleEnforcement.DefaultApkDaysForNewVehicle})
    local row=MySQL.single.await('SELECT mileage,next_service_km,roadworthy,apk_expires FROM thootje_pch_vehicles WHERE plate=?',{plate})
    if row and row.next_service_km and row.mileage>=row.next_service_km then
        TriggerClientEvent('thootje-pechhulp:client:serviceDue',src,plate,row.mileage,row.next_service_km)
    end
end)

-- Vehicle enforcement status is queried when a driver enters a vehicle, then checked periodically.
lib.callback.register('thootje-pechhulp:server:checkVehicle',function(src,plate)
    plate=plateClean(plate)
    if plate=='' then return {allowed=true} end
    local row=MySQL.single.await('SELECT roadworthy,apk_expires,scrapped,mileage,next_service_km FROM thootje_pch_vehicles WHERE plate=?',{plate})
    if not row then return {allowed=true,registered=false} end
    local expired = Config.VehicleEnforcement.BlockExpiredApk and row.apk_expires and tostring(row.apk_expires) < os.date('%Y-%m-%d %H:%M:%S')
    local disapproved = Config.VehicleEnforcement.BlockDisapproved and (tonumber(row.roadworthy)==0 or tonumber(row.scrapped)==1)
    return {allowed=not expired and not disapproved,expired=expired==true,disapproved=disapproved==true,mileage=row.mileage,nextService=row.next_service_km}
end)

CreateThread(function()
    while true do
        Wait(60000)
        local expired=MySQL.query.await("SELECT plate FROM thootje_pch_vehicles WHERE roadworthy=1 AND apk_expires IS NOT NULL AND apk_expires < NOW()")
        for _,v in ipairs(expired or {}) do
            MySQL.update.await('UPDATE thootje_pch_vehicles SET roadworthy=0 WHERE plate=?',{v.plate})
            publishRoadworthy(v.plate,false,'APK verlopen')
        end
    end
end)

RegisterNetEvent('thootje-pechhulp:server:recordInspection',function(data)
    local src=source; if not staff(src) or type(data)~='table' then return end
    local plate=plateClean(data.plate); if #plate<2 then return end
    local approved=data.approved==true
    local mileage=math.max(0,tonumber(data.mileage) or 0)
    local note=tostring(data.note or ''):sub(1,500)
    local nextApk=os.date('%Y-%m-%d %H:%M:%S',os.time()+Config.Inspection.ApkIntervalDays*86400)
    MySQL.insert.await('INSERT INTO thootje_pch_vehicles (plate,owner_identifier,model,mileage,last_service_km,next_service_km,apk_expires,roadworthy,inspection_note,scrapped) VALUES (?,?,?,?,?,?,?,?,?,0) ON DUPLICATE KEY UPDATE mileage=GREATEST(mileage,VALUES(mileage)),last_service_km=VALUES(last_service_km),next_service_km=VALUES(next_service_km),apk_expires=VALUES(apk_expires),roadworthy=VALUES(roadworthy),inspection_note=VALUES(inspection_note),scrapped=0',
      {plate,tostring(data.owner or ''),tostring(data.model or 'Onbekend'),mileage,mileage,mileage+Config.Inspection.ServiceIntervalKm,nextApk,approved and 1 or 0,note})
    MySQL.insert.await('INSERT INTO thootje_pch_maintenance (plate,staff_identifier,staff_name,service_type,result,mileage,note) VALUES (?,?,?,?,?,?,?)',
      {plate,ident(src),GetPlayerName(src),'APK',approved and 'goedgekeurd' or 'afgekeurd',mileage,note})
    publishRoadworthy(plate,approved,approved and 'APK goedgekeurd' or 'Voertuig afgekeurd')
    notify(src,approved and 'Voertuig APK-goedgekeurd.' or 'Voertuig afgekeurd. Het voertuig mag niet rijden.','success')
end)

RegisterNetEvent('thootje-pechhulp:server:recordService',function(data)
    local src=source; if not staff(src) or type(data)~='table' then return end
    local plate=plateClean(data.plate); if #plate<2 then return end
    local mileage=math.max(0,tonumber(data.mileage) or 0)
    local kind=tostring(data.kind or 'kleine_beurt')
    if kind~='kleine_beurt' then return end
    MySQL.update.await('UPDATE thootje_pch_vehicles SET mileage=GREATEST(mileage,?),last_service_km=?,next_service_km=? WHERE plate=?',
      {mileage,mileage,mileage+Config.Inspection.ServiceIntervalKm,plate})
    MySQL.insert.await('INSERT INTO thootje_pch_maintenance (plate,staff_identifier,staff_name,service_type,result,mileage,note) VALUES (?,?,?,?,?,?,?)',
      {plate,ident(src),GetPlayerName(src),'kleine_beurt','uitgevoerd',mileage,tostring(data.note or ''):sub(1,500)})
    notify(src,'Kleine beurt geregistreerd. Volgende beurt over '..Config.Inspection.ServiceIntervalKm..' km.','success')
end)

RegisterNetEvent('thootje-pechhulp:server:diagnostic',function(data)
    local src=source; if not staff(src) or type(data)~='table' then return end
    local plate=plateClean(data.plate)
    local engine=tonumber(data.engine) or 1000
    local body=tonumber(data.body) or 1000
    local fuel=tonumber(data.fuel) or 100
    local tyres=tonumber(data.tyres) or 0
    local battery=tonumber(data.battery) or 100
    local roadside=engine>=Config.Diagnostics.RoadsideEngineHealth and body>=Config.Diagnostics.RoadsideBodyHealth
    local severity=(engine<Config.Diagnostics.RoadsideEngineHealth or body<Config.Diagnostics.RoadsideBodyHealth) and 'sleepdienst aanbevolen' or 'reparatie op locatie mogelijk'
    local report={plate=plate,engine=math.floor(engine),body=math.floor(body),fuel=math.floor(fuel),tyres=tyres,battery=math.floor(battery),roadside=roadside,severity=severity}
    TriggerClientEvent('thootje-pechhulp:client:diagnosticResult',src,report)
    MySQL.insert.await('INSERT INTO thootje_pch_maintenance (plate,staff_identifier,staff_name,service_type,result,note) VALUES (?,?,?,?,?,?)',
      {plate,ident(src),GetPlayerName(src),'diagnose',severity,json.encode(report)})
end)

RegisterNetEvent('thootje-pechhulp:server:service',function(data)
    local src=source; if not staff(src) or type(data)~='table' then return end
    local kind=tostring(data.kind or '')
    local allowed={battery=true,fuel=true,repair=true,tow=true}
    if not allowed[kind] then return end
    local plate=plateClean(data.plate)
    local fee=({battery=Config.Invoice.Repair,fuel=Config.Invoice.Repair,repair=Config.Invoice.Repair,tow=Config.Invoice.Tow})[kind]
    local owner=tostring(data.owner or '')
    local cut=discount(owner,kind=='tow' and 'tow' or 'normal')
    fee=math.floor(fee*(1-cut/100))
    MySQL.insert.await('INSERT INTO thootje_pch_maintenance (plate,staff_identifier,staff_name,service_type,result,mileage,note) VALUES (?,?,?,?,?,?,?)',
      {plate,ident(src),GetPlayerName(src),kind,'uitgevoerd',tonumber(data.mileage) or 0,tostring(data.note or ''):sub(1,300)})
    TriggerClientEvent('thootje-pechhulp:client:invoicePrompt',src,{owner=owner,plate=plate,kind=kind,amount=fee,description='Pechhulp: '..kind})
    notify(src,'Service geregistreerd. Maak de factuur aan via de tablet.','success')
end)

local function sendBillingInvoice(target, amount, description, pechhulpInvoiceId)
    local exportName=Config.Billing.CreateInvoiceExport
    if exportName and exportName~='' then
        local ok,result=pcall(function()
            return exports[Config.Billing.Resource][exportName](target,amount,description)
        end)
        if ok and result~=false then return true,result end
    end
    if Config.Billing.EnableEventFallback then
        TriggerEvent(Config.Billing.CreateInvoiceEvent,target,amount,description,pechhulpInvoiceId)
        return true,'event'
    end
    return false,'THOOTJE-BILLING API niet bevestigd; lokale factuur blijft geregistreerd.'
end

RegisterNetEvent('thootje-pechhulp:server:createInvoice',function(data)
    local src=source; if not staff(src) or type(data)~='table' then return end
    local target=tonumber(data.target); local amount=math.floor(tonumber(data.amount) or 0)
    if not target or not GetPlayerName(target) or amount<1 or amount>1000000 then return end
    local desc=tostring(data.description or 'Pechhulp factuur'):sub(1,180)
    local owner=ident(target)
    amount=math.floor(amount*(1-discount(owner,'normal')/100))
    local inv=MySQL.insert.await('INSERT INTO thootje_pch_invoices (customer_identifier,customer_name,staff_identifier,staff_name,amount,description,status) VALUES (?,?,?,?,?,?,?)',
      {owner,GetPlayerName(target),ident(src),GetPlayerName(src),amount,desc,'open'})
    local ok,detail=sendBillingInvoice(target,amount,desc,inv)
    if ok then
        MySQL.update.await("UPDATE thootje_pch_invoices SET billing_status='sent' WHERE id=?",{inv})
    else
        MySQL.update.await("UPDATE thootje_pch_invoices SET billing_status='local_only' WHERE id=?",{inv})
    end
    TriggerClientEvent('thootje-pechhulp:client:invoiceReceived',target,{id=inv,amount=amount,description=desc,billing=ok})
    notify(src,ok and ('Factuur #%s via THOOTJE-BILLING verstuurd.'):format(inv) or ('Factuur #%s lokaal opgeslagen. %s'):format(inv,tostring(detail)),'success')
end)

RegisterNetEvent('thootje-pechhulp:server:subscribe',function(plan)
    local src=source; local id=ident(src); local cfg=Config.SubscriptionPlans[plan]
    if not id or not cfg then return end
    local ok,result=pcall(function() return exports['thootje-banking']:RemoveBankMoney(src,cfg.price,'Pechhulp abonnement') end)
    if not ok or result==false then notify(src,'Betaling mislukt of banking-koppeling ontbreekt.','error'); return end
    MySQL.insert.await('INSERT INTO thootje_pch_subscriptions (owner_identifier,plan,expires_at) VALUES (?,?,DATE_ADD(NOW(),INTERVAL 30 DAY)) ON DUPLICATE KEY UPDATE plan=VALUES(plan),expires_at=VALUES(expires_at)',{id,plan})
    notify(src,cfg.label..' geactiveerd voor 30 dagen.','success')
end)

RegisterNetEvent('thootje-pechhulp:server:craft',function(item)
    local src=source; if not staff(src) then return end
    local recipe=Config.Crafting[item]; if not recipe then return end
    for ingredient,count in pairs(recipe.ingredients) do
        if not THOOTJE_PCH.HasItem(src,ingredient,count) then notify(src,'Niet genoeg materialen: '..ingredient,'error'); return end
    end
    for ingredient,count in pairs(recipe.ingredients) do
        if not THOOTJE_PCH.RemoveItem(src,ingredient,count) then notify(src,'Materiaal kon niet worden verwijderd.','error'); return end
    end
    THOOTJE_PCH.AddItem(src,item,recipe.output)
    notify(src,recipe.label..' gemaakt.','success')
end)

RegisterNetEvent('thootje-pechhulp:server:scrap',function(plate,parts)
    local src=source; if not staff(src) then return end
    plate=plateClean(plate); if type(parts)~='table' then return end
    local ped=GetPlayerPed(src); local pos=GetEntityCoords(ped)
    if #(pos-Config.ScrapYard.coords)>25.0 then notify(src,'Je bent niet bij de autosloperij.','error'); return end
    local veh=GetVehiclePedIsIn(ped,false)
    if veh==0 or plateClean(GetVehicleNumberPlateText(veh))~=plate then notify(src,'Ga in het voertuig staan dat je wilt slopen.','error'); return end
    local row=MySQL.single.await('SELECT roadworthy FROM thootje_pch_vehicles WHERE plate=?',{plate})
    if row and row.roadworthy==1 then notify(src,'Keur eerst het voertuig af voordat je het sloopt.','error'); return end
    for part,count in pairs(parts) do
        local item=Config.Service.parts[part]
        count=math.min(10,math.max(0,math.floor(tonumber(count) or 0)))
        if item and count>0 then THOOTJE_PCH.AddItem(src,item,count) end
    end
    MySQL.update.await('UPDATE thootje_pch_vehicles SET scrapped=1,roadworthy=0 WHERE plate=?',{plate})
    MySQL.insert.await('INSERT INTO thootje_pch_maintenance (plate,staff_identifier,staff_name,service_type,result,note) VALUES (?,?,?,?,?,?)',{plate,ident(src),GetPlayerName(src),'sloop','gesloopt','Onderdelen teruggewonnen'})
    TriggerClientEvent('thootje-pechhulp:client:deleteVehicle',src,NetworkGetNetworkIdFromEntity(veh))
    notify(src,'Voertuig gesloopt en onderdelen teruggewonnen.','success')
end)

lib.callback.register('thootje-pechhulp:server:subscription',function(src)
    return subscription(ident(src))
end)
