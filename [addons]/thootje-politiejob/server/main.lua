local cuffed,escorted,jailed={},{},{}
local function notify(s,m,k) THOOTJE_POLICE.Notify(s,m,k) end
local function auth(src,permission)
 local min=Config.Permissions[permission] or 0
 local ok,grade,why=THOOTJE_POLICE.IsPolice(src,min,true)
 if not ok then
  if grade=='duty' then notify(src,Config.Locale.offDuty,'error')
  elseif grade=='grade' then notify(src,Config.Locale.notAllowed,'error')
  else notify(src,Config.Locale.noJob,'error') end
  return false
 end
 return true,grade
end
local function near(a,b,d)
 if not GetPlayerName(b) then return false end
 local p1,p2=GetPlayerPed(a),GetPlayerPed(b)
 return p1~=0 and p2~=0 and #(GetEntityCoords(p1)-GetEntityCoords(p2))<=d
end
local function policeRoster()
 local out={}
 for _,p in ipairs(GetPlayers()) do
  local s=tonumber(p);local j,g,d=THOOTJE_POLICE.GetPlayerJob(s)
  if j==Config.JobName then out[#out+1]={id=s,name=THOOTJE_POLICE.GetCharacterName(s),grade=Config.Ranks[g] or ('Rang '..g),onduty=d==true} end
 end
 return out
end
local function mdtData()
 return {
  reports=MySQL.query.await('SELECT id,title,description,suspect_name,officer_name,created_at FROM thootje_police_reports ORDER BY id DESC LIMIT 50') or {},
  fines=MySQL.query.await([[
   SELECT id,sender_name AS officer_name,recipient_name AS suspect_name,
          amount,SUBSTRING(description, 15) AS reason,status,created_at,invoice_number
   FROM thootje_billing_invoices
   WHERE description LIKE 'Politieboete:%'
   ORDER BY id DESC LIMIT 30
  ]]) or {},
  police=policeRoster(),officer='Politie MDT'
 }
end
RegisterNetEvent('thootje-politiejob:server:openMenu',function()
 local s=source;if auth(s,'mdt') then notify(s,'Politie: /mdt, /cuff, /escort, /search, /fine [id] [bedrag] [reden], /jail [id] [minuten], /panic, /pdarmory, /pdgarage','info') end
end)
RegisterNetEvent('thootje-politiejob:server:openMDT',function()
 local s=source;if not auth(s,'mdt') then return end
 TriggerClientEvent('thootje-politiejob:client:openMDT',s,mdtData())
end)
RegisterNetEvent('thootje-politiejob:server:searchPlayer',function(query)
 local s=source;if not auth(s,'mdt') then return end
 query=tostring(query or ''):lower();if #query<1 or #query>60 then return end
 local out={}
 for _,p in ipairs(GetPlayers()) do
  local id=tonumber(p);local name=THOOTJE_POLICE.GetCharacterName(id)
  if name:lower():find(query,1,true) or tostring(id)==query then
   local j,g,d=THOOTJE_POLICE.GetPlayerJob(id)
   out[#out+1]={id=id,name=name,job=j or 'Onbekend',grade=g or 0,onduty=d==true}
  end
 end
 TriggerClientEvent('thootje-politiejob:client:searchResults',s,out)
end)
RegisterNetEvent('thootje-politiejob:server:createReport',function(data)
 local s=source;if not auth(s,'reports') or type(data)~='table' then return end
 local title=tostring(data.title or ''):sub(1,Config.MaxReportTitle)
 local desc=tostring(data.description or ''):sub(1,Config.MaxReportLength)
 local suspect=tostring(data.suspect or ''):sub(1,100)
 if #title<3 or #desc<10 then notify(s,'Vul een geldige titel en omschrijving in.','error');return end
 MySQL.insert.await('INSERT INTO thootje_police_reports (officer_identifier,officer_name,suspect_name,title,description) VALUES (?,?,?,?,?)',{
  THOOTJE_POLICE.GetIdentifier(s),THOOTJE_POLICE.GetCharacterName(s),suspect,title,desc
 })
 notify(s,'Rapport opgeslagen.','success')
 TriggerClientEvent('thootje-politiejob:client:updateMDT',s,mdtData())
end)
RegisterNetEvent('thootje-politiejob:server:cuff',function(target)
 local s=source;target=tonumber(target);if not auth(s,'cuff') then return end
 if not target or target==s or not near(s,target,Config.CuffDistance) then notify(s,Config.Locale.tooFar,'error');return end
 cuffed[target]=not cuffed[target]
 TriggerClientEvent('thootje-politiejob:client:playCuff',s)
 TriggerClientEvent('thootje-politiejob:client:cuff',target,cuffed[target])
 if not cuffed[target] then escorted[target]=nil;TriggerClientEvent('thootje-politiejob:client:escort',target,nil) end
end)
RegisterNetEvent('thootje-politiejob:server:escort',function(target)
 local s=source;target=tonumber(target);if not auth(s,'escort') then return end
 if not target or not near(s,target,Config.EscortDistance) or not cuffed[target] then notify(s,'Speler moet geboeid en dichtbij zijn.','error');return end
 if escorted[target]==s then escorted[target]=nil;TriggerClientEvent('thootje-politiejob:client:escort',target,nil)
 else escorted[target]=s;TriggerClientEvent('thootje-politiejob:client:escort',target,s) end
end)
RegisterNetEvent('thootje-politiejob:server:search',function(target)
 local s=source;target=tonumber(target);if not auth(s,'search') then return end
 if not target or not near(s,target,Config.SearchDistance) then notify(s,Config.Locale.tooFar,'error');return end
 local inventory=THOOTJE_POLICE.GetInventory(target)
 if not inventory then notify(s,'THOOTJE-INVENTORY is niet bereikbaar.','error');return end
 local items={}
 for _,slot in pairs(inventory) do
  if type(slot)=='table' and slot.name and (tonumber(slot.count) or 0)>0 then
   items[#items+1]={name=tostring(slot.name),label=tostring(slot.label or slot.name),count=tonumber(slot.count),slot=tonumber(slot.slot) or 0}
  end
 end
 table.sort(items,function(a,b) return a.slot<b.slot end)
 TriggerClientEvent('thootje-politiejob:client:playFrisk',s)
 TriggerClientEvent('thootje-politiejob:client:showInventory',s,target,THOOTJE_POLICE.GetCharacterName(target),items)
 notify(s,'Inventaris geopend. Je kunt items innemen zolang de verdachte geboeid en dichtbij is.','success')
 notify(target,'Een agent fouilleert je.','info')
end)

RegisterNetEvent('thootje-politiejob:server:confiscateItem',function(target,itemName,amount)
 local s=source; target=tonumber(target); itemName=tostring(itemName or '')
 amount=math.floor(tonumber(amount) or 0)
 if not auth(s,'search') then return end
 if not target or target==s or not near(s,target,Config.SearchDistance) then notify(s,Config.Locale.tooFar,'error');return end
 if not cuffed[target] then notify(s,'De verdachte moet eerst geboeid zijn.','error');return end
 if #itemName<1 or #itemName>64 or amount<1 or amount>Config.MaxConfiscateAmount then notify(s,'Ongeldige hoeveelheid of item.','error');return end
 local inventory=THOOTJE_POLICE.GetInventory(target)
 if not inventory then notify(s,'THOOTJE-INVENTORY is niet bereikbaar.','error');return end
 local available=0
 for _,slot in pairs(inventory) do
  if type(slot)=='table' and slot.name==itemName then available=available+(tonumber(slot.count) or 0) end
 end
 if available<amount then notify(s,'De speler heeft niet genoeg van dit item.','error');return end
 if not THOOTJE_POLICE.RemoveInventoryItem(target,itemName,amount) then notify(s,'Item kon niet uit de inventaris worden verwijderd.','error');return end
 notify(s,('%sx %s ingenomen.'):format(amount,itemName),'success')
 notify(target,('%sx %s is door de politie ingenomen.'):format(amount,itemName),'error')
 local updated=THOOTJE_POLICE.GetInventory(target) or {}; local items={}
 for _,slot in pairs(updated) do
  if type(slot)=='table' and slot.name and (tonumber(slot.count) or 0)>0 then
   items[#items+1]={name=tostring(slot.name),label=tostring(slot.label or slot.name),count=tonumber(slot.count),slot=tonumber(slot.slot) or 0}
  end
 end
 table.sort(items,function(a,b) return a.slot<b.slot end)
 TriggerClientEvent('thootje-politiejob:client:showInventory',s,target,THOOTJE_POLICE.GetCharacterName(target),items)
end)
RegisterNetEvent('thootje-politiejob:server:requestArmory',function()
 local s=source;if auth(s,'armory') then
  local labels={};for i,v in ipairs(Config.Armory) do labels[#labels+1]=i..'. '..v.label end
  notify(s,'Wapenkluis: '..table.concat(labels,' | ')..' — /pdweapon [nummer]','info')
 end
end)
RegisterNetEvent('thootje-politiejob:server:giveWeapon',function(index)
 local s=source;if not auth(s,'armory') then return end
 index=tonumber(index);local item=index and Config.Armory[index]
 if not item then notify(s,Config.Locale.invalid or 'Ongeldige keuze.','error');return end
 TriggerClientEvent('thootje-politiejob:client:giveWeapon',s,item.weapon,item.label)
end)
RegisterNetEvent('thootje-politiejob:server:requestGarage',function()
 local s=source;local ok,grade=auth(s,'vehicles');if not ok then return end
 local list={};for i,v in ipairs(Config.Vehicles) do if grade>=v.minGrade then list[#list+1]=v end end
 local labels={};for i,v in ipairs(list) do labels[#labels+1]=i..'. '..v.label end
 notify(s,'Dienstgarage: '..table.concat(labels,' | ')..' — /pdvehicle [nummer]','info')
end)
RegisterNetEvent('thootje-politiejob:server:spawnVehicle',function(index)
 local s=source;local ok,grade=auth(s,'vehicles');if not ok then return end
 index=tonumber(index);local list={}
 for _,v in ipairs(Config.Vehicles) do if grade>=v.minGrade then list[#list+1]=v end end
 local v=index and list[index];if not v then notify(s,Config.Locale.notAllowed,'error');return end
 TriggerClientEvent('thootje-politiejob:client:spawnVehicle',s,v.model)
end)
RegisterNetEvent('thootje-politiejob:server:fine',function(data)
 local s=source;if not auth(s,'fine') or type(data)~='table' then return end
 local target=tonumber(data.target);local amount=math.floor(tonumber(data.amount) or 0);local reason=tostring(data.reason or ''):sub(1,Config.MaxFineReason)
 if not target or target==s or not near(s,target,Config.SearchDistance) or amount<Config.FineMin or amount>Config.FineMax or #reason<3 then notify(s,'Ongeldige boetegegevens.','error');return end
 local ok,invoiceId,invoiceNumber=THOOTJE_POLICE.CreateFineInvoice(s,target,amount,reason)
 if not ok then notify(s,('Boete kon niet in THOOTJE-BILLING worden aangemaakt (%s).'):format(tostring(invoiceId)),'error');return end
 notify(s,('Boete opgeslagen in THOOTJE-BILLING (%s).'):format(tostring(invoiceNumber or invoiceId)),'success')
 notify(target,('Je hebt een politieboete van $%s ontvangen: %s. Je vindt deze in THOOTJE-BILLING.'):format(amount,reason),'error')
 TriggerClientEvent('thootje-politiejob:client:updateMDT',s,mdtData())
end)
local function release(target)
 jailed[target]=nil;local c=Config.ReleaseCoords
 TriggerClientEvent('thootje-politiejob:client:release',target,{x=c.x,y=c.y,z=c.z,w=c.w})
end
RegisterNetEvent('thootje-politiejob:server:jail',function(target,minutes)
 local s=source;target=tonumber(target);minutes=math.floor(tonumber(minutes) or 0)
 if not auth(s,'jail') then return end
 if not target or target==s or not GetPlayerName(target) or minutes<1 or minutes>Config.JailMaxMinutes then notify(s,'Ongeldige gevangenisstraf.','error');return end
 local c=Config.JailCoords;jailed[target]=os.time()+minutes*60
 TriggerClientEvent('thootje-politiejob:client:jail',target,{x=c.x,y=c.y,z=c.z,w=c.w},minutes)
 MySQL.insert.await('INSERT INTO thootje_police_jail_logs (officer_identifier,officer_name,suspect_identifier,suspect_name,minutes) VALUES (?,?,?,?,?)',{
  THOOTJE_POLICE.GetIdentifier(s),THOOTJE_POLICE.GetCharacterName(s),THOOTJE_POLICE.GetIdentifier(target),THOOTJE_POLICE.GetCharacterName(target),minutes
 })
 notify(s,('Speler %s opgesloten voor %s minuten.'):format(target,minutes),'success')
end)
RegisterNetEvent('thootje-politiejob:server:unjail',function(target)
 local s=source;if not auth(s,'jail') then return end
 target=tonumber(target);if target and jailed[target] then release(target);notify(s,'Speler vrijgelaten.','success') else notify(s,'Speler staat niet in de gevangenis.','error') end
end)
RegisterNetEvent('thootje-politiejob:server:panic',function()
 local s=source;if not auth(s,'mdt') then return end
 local name=THOOTJE_POLICE.GetCharacterName(s)
 for _,p in ipairs(GetPlayers()) do local id=tonumber(p);local j,_,d=THOOTJE_POLICE.GetPlayerJob(id);if j==Config.JobName and d then notify(id,'PANIEKMELDING: '..name..' heeft assistentie nodig!','error') end end
 print(('[THOOTJE-POLITIE] PANIC %s (%s)'):format(name,s))
end)
CreateThread(function()
 while true do
  Wait(Config.JailTickSeconds*1000)
  for id,expiry in pairs(jailed) do
   if not GetPlayerName(id) then jailed[id]=nil
   elseif os.time()>=expiry then release(id)
   else TriggerClientEvent('thootje-politiejob:client:jailTime',id,math.ceil((expiry-os.time())/60)) end
  end
 end
end)
AddEventHandler('playerDropped',function()
 local s=source;cuffed[s]=nil;jailed[s]=nil;escorted[s]=nil
 for target,officer in pairs(escorted) do if officer==s then escorted[target]=nil;TriggerClientEvent('thootje-politiejob:client:escort',target,nil) end end
end)
exports('IsCuffed',function(src) return cuffed[src]==true end)
exports('IsJailed',function(src) return jailed[src]~=nil end)
exports('GetOnlinePolice',policeRoster)
