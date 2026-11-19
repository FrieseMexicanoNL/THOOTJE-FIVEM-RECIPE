THOOTJE_POLICE = {}
function THOOTJE_POLICE.GetIdentifier(src)
 local ok,data=pcall(function() return exports['thootje-core']:GetPlayerData(src) end)
 if ok and type(data)=='table' then return data.citizenid or data.charid or data.identifier or data.license end
 for _,id in ipairs(GetPlayerIdentifiers(src)) do if id:sub(1,8)=='license:' then return id end end
 return nil
end
function THOOTJE_POLICE.GetCharacterName(src)
 local ok,data=pcall(function() return exports['thootje-core']:GetPlayerData(src) end)
 if ok and type(data)=='table' then
  if data.charinfo then
   local n=((data.charinfo.firstname or '')..' '..(data.charinfo.lastname or '')):gsub('^%s*(.-)%s*$','%1')
   if n~='' then return n end
  end
  return data.name or data.fullname or GetPlayerName(src) or 'Onbekend'
 end
 return GetPlayerName(src) or 'Onbekend'
end
function THOOTJE_POLICE.GetPlayerJob(src)
 local ok,j=pcall(function() return exports['thootje-jobs']:GetJob(src) end)
 if ok and type(j)=='table' then return j.name or j.job or j.id,tonumber(j.grade or j.grade_level or 0),j.onduty==true or j.onDuty==true end
 local s=Player(src).state; local d=s and s.thootjeJob
 if type(d)=='table' then return d.name or d.job,tonumber(d.grade or 0),d.onduty==true or d.onDuty==true end
 return nil,0,false
end
function THOOTJE_POLICE.IsPolice(src,minGrade,requireDuty)
 local job,grade,duty=THOOTJE_POLICE.GetPlayerJob(src)
 if job~=Config.JobName then return false,'job' end
 if requireDuty and Config.RequireDuty and not duty then return false,'duty' end
 if (grade or 0)<(minGrade or 0) then return false,'grade' end
 return true,grade,duty
end
function THOOTJE_POLICE.Notify(src,msg,kind) TriggerClientEvent(Config.NotifyEvent,src,msg,kind or 'info') end


function THOOTJE_POLICE.GetInventory(src)
 local ok, items = pcall(function() return exports['thootje-inventory']:GetInventory(src) end)
 if not ok or type(items) ~= 'table' then return nil end
 return items
end
function THOOTJE_POLICE.RemoveInventoryItem(src, itemName, amount)
 local ok, result = pcall(function() return exports['thootje-inventory']:RemoveItem(src, itemName, amount) end)
 return ok and result == true
end
function THOOTJE_POLICE.CreateFineInvoice(officer, target, amount, reason)
 local description = ('Politieboete: %s'):format(tostring(reason or 'Overtreding'))
 local ok, success, invoiceId, invoiceNumber = pcall(function()
  return exports['thootje-billing']:CreateInvoice(officer, target, amount, description, {
   noFee = true, noPayout = true, senderName = 'Politie - ' .. THOOTJE_POLICE.GetCharacterName(officer), requireNearby = false
  })
 end)
 if not ok then return false, 'billing_unavailable' end
 if success ~= true then return false, invoiceId or 'invoice_failed' end
 return true, invoiceId, invoiceNumber
end
