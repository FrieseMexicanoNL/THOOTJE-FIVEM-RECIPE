local callCooldown, actionCooldown = {}, {}
local function notify(src, msg, kind) THOOTJE_EMS.Notify(src, msg, kind) end

local function rateOk(src, bucket)
    local now = GetGameTimer()
    local key = tostring(src) .. ':' .. bucket
    if actionCooldown[key] and now - actionCooldown[key] < Config.Security.ActionCooldownMs then return false end
    actionCooldown[key] = now
    return true
end

local function auth(src, permission)
    local ok, grade, job = THOOTJE_EMS.IsMedic(src, permission)
    if ok then return true, grade, job end
    if grade == 'duty' then notify(src, Config.Locale.offDuty, 'error')
    elseif grade == 'grade' then notify(src, 'Je hebt niet de juiste rang voor deze handeling.', 'error')
    else notify(src, Config.Locale.noJob, 'error') end
    return false
end

local function isNear(src, target, distance)
    if not target or not GetPlayerName(target) then return false end
    local p1, p2 = GetPlayerPed(src), GetPlayerPed(target)
    if p1 == 0 or p2 == 0 then return false end
    return #(GetEntityCoords(p1) - GetEntityCoords(p2)) <= distance
end

local function roster()
    local result = {}
    for _, player in ipairs(GetPlayers()) do
        local id = tonumber(player)
        local job = THOOTJE_EMS.GetJob(id)
        if job and job.name == Config.JobName then
            result[#result + 1] = {
                id = id,
                name = THOOTJE_EMS.GetCharacterName(id),
                grade = job.grade,
                gradeLabel = job.gradeLabel,
                onduty = job.onduty == true
            }
        end
    end
    table.sort(result, function(a, b) return a.grade > b.grade end)
    return result
end

local function getCalls()
    return MySQL.query.await([[
        SELECT id, caller_identifier, caller_name, call_type, message,
               x, y, z, status, assigned_identifier, assigned_name,
               created_at, updated_at
        FROM thootje_ems_calls
        WHERE status IN ('open','assigned')
        ORDER BY id DESC LIMIT 50
    ]]) or {}
end

local function getRecentTreatments()
    return MySQL.query.await([[
        SELECT id, medic_name, patient_name, treatment, item_name, created_at
        FROM thootje_ems_treatments ORDER BY id DESC LIMIT 20
    ]]) or {}
end

local function dashboardData()
    local calls = getCalls()
    local openCount = 0
    for _, call in ipairs(calls) do if call.status == 'open' then openCount = openCount + 1 end end
    return {
        calls = calls,
        roster = roster(),
        treatments = getRecentTreatments(),
        openCalls = openCount,
        medic = 'Ambulancedienst'
    }
end

local function updateMedicTable(src)
    TriggerClientEvent('thootje-ambulancejob:client:update', src, dashboardData())
end

local function broadcastCallUpdate()
    local data = dashboardData()
    for _, player in ipairs(GetPlayers()) do
        local id = tonumber(player)
        local job = THOOTJE_EMS.GetJob(id)
        if job and job.name == Config.JobName and job.onduty then
            TriggerClientEvent('thootje-ambulancejob:client:update', id, data)
        end
    end
end

local function getNearbyPlayers(src)
    local origin = GetEntityCoords(GetPlayerPed(src))
    local result = {}
    for _, player in ipairs(GetPlayers()) do
        local id = tonumber(player)
        if id ~= src then
            local ped = GetPlayerPed(id)
            if ped ~= 0 then
                local coords = GetEntityCoords(ped)
                local distance = #(origin - coords)
                if distance <= 15.0 then
                    local health = GetEntityHealth(ped)
                    result[#result + 1] = {
                        id = id,
                        name = THOOTJE_EMS.GetCharacterName(id),
                        distance = math.floor(distance * 10) / 10,
                        health = health,
                        down = health <= 101
                    }
                end
            end
        end
    end
    table.sort(result, function(a, b) return a.distance < b.distance end)
    return result
end

RegisterNetEvent('thootje-ambulancejob:server:openTablet', function()
    local src = source
    if not auth(src, 'tablet') then return end
    TriggerClientEvent('thootje-ambulancejob:client:openTablet', src, dashboardData(), getNearbyPlayers(src))
end)

RegisterNetEvent('thootje-ambulancejob:server:refresh', function()
    local src = source
    if not auth(src, 'tablet') then return end
    TriggerClientEvent('thootje-ambulancejob:client:update', src, dashboardData())
    TriggerClientEvent('thootje-ambulancejob:client:nearby', src, getNearbyPlayers(src))
end)

RegisterNetEvent('thootje-ambulancejob:server:nearby', function()
    local src = source
    if not auth(src, 'tablet') then return end
    TriggerClientEvent('thootje-ambulancejob:client:nearby', src, getNearbyPlayers(src))
end)

RegisterNetEvent('thootje-ambulancejob:server:toggleDuty', function()
    local src = source
    local job = THOOTJE_EMS.GetJob(src)
    if not job or job.name ~= Config.JobName then return notify(src, Config.Locale.noJob, 'error') end
    local success = exports['thootje-jobs']:SetDuty(src, not job.onduty)
    if success then
        notify(src, job.onduty and 'Je bent uit dienst gegaan.' or 'Je bent in dienst gegaan.', 'success')
        if not job.onduty then
            SetTimeout(300, function()
                if GetPlayerName(src) then updateMedicTable(src); broadcastCallUpdate() end
            end)
        end
    else
        notify(src, 'Dienststatus kon niet worden aangepast.', 'error')
    end
end)

RegisterNetEvent('thootje-ambulancejob:server:createCall', function(callType, message, coords)
    local src = source
    if not rateOk(src, 'call') then return end
    if type(coords) ~= 'table' then return end
    callType = tostring(callType or 'other')
    local allowed = false
    for _, item in ipairs(Config.CallTypes) do if item.id == callType then allowed = true break end end
    if not allowed then callType = 'other' end
    message = tostring(message or ''):gsub('[\r\n]', ' '):sub(1, Config.Security.MaxCallText)
    if #message < 5 then message = 'Hulpdiensten gewenst.' end
    local x, y, z = tonumber(coords.x), tonumber(coords.y), tonumber(coords.z)
    if not x or not y or not z or math.abs(x) > Config.Security.MaxCallDistanceFromMap or math.abs(y) > Config.Security.MaxCallDistanceFromMap then
        return notify(src, 'Locatie van de melding kon niet worden bepaald.', 'error')
    end
    local identifier = THOOTJE_EMS.GetIdentifier(src)
    if not identifier then return end
    local id = MySQL.insert.await([[
        INSERT INTO thootje_ems_calls
        (caller_identifier, caller_name, call_type, message, x, y, z, status)
        VALUES (?,?,?,?,?,?,?,'open')
    ]], { identifier, THOOTJE_EMS.GetCharacterName(src), callType, message, x, y, z })
    if not id then return notify(src, 'Melding opslaan is mislukt.', 'error') end
    notify(src, ('Je 112-melding is verstuurd. Meldingsnummer #%s.'):format(id), 'success')
    for _, player in ipairs(GetPlayers()) do
        local medic = tonumber(player)
        local job = THOOTJE_EMS.GetJob(medic)
        if job and job.name == Config.JobName and job.onduty then
            notify(medic, ('Nieuwe 112-melding #%s: %s'):format(id, message), 'warning')
        end
    end
    broadcastCallUpdate()
end)

RegisterNetEvent('thootje-ambulancejob:server:acceptCall', function(callId)
    local src = source
    if not auth(src, 'calls') or not rateOk(src, 'accept') then return end
    callId = tonumber(callId)
    if not callId then return end
    local identifier = THOOTJE_EMS.GetIdentifier(src)
    local name = THOOTJE_EMS.GetCharacterName(src)
    local changed = MySQL.update.await([[
        UPDATE thootje_ems_calls
        SET status='assigned', assigned_identifier=?, assigned_name=?, assigned_source=?, updated_at=NOW()
        WHERE id=? AND status='open'
    ]], { identifier, name, src, callId })
    if changed ~= 1 then return notify(src, Config.Locale.noCall, 'error') end
    notify(src, Config.Locale.assigned, 'success')
    local call = MySQL.single.await('SELECT x,y,z,message FROM thootje_ems_calls WHERE id=?', { callId })
    if call then TriggerClientEvent('thootje-ambulancejob:client:setWaypoint', src, call.x, call.y, call.z) end
    broadcastCallUpdate()
end)

RegisterNetEvent('thootje-ambulancejob:server:completeCall', function(callId)
    local src = source
    if not auth(src, 'calls') then return end
    callId = tonumber(callId)
    if not callId then return end
    local identifier = THOOTJE_EMS.GetIdentifier(src)
    local changed = MySQL.update.await([[
        UPDATE thootje_ems_calls
        SET status='completed', updated_at=NOW()
        WHERE id=? AND status='assigned' AND assigned_identifier=?
    ]], { callId, identifier })
    if changed ~= 1 then return notify(src, 'Alleen de toegewezen eenheid kan deze melding afronden.', 'error') end
    notify(src, Config.Locale.completed, 'success')
    broadcastCallUpdate()
end)

RegisterNetEvent('thootje-ambulancejob:server:treat', function(target, treatment)
    local src = source
    if not auth(src, 'treatment') or not rateOk(src, 'treat') then return end
    target = tonumber(target)
    treatment = tostring(treatment or '')
    local definition = Config.MedicalItems[treatment]
    if not definition then return notify(src, Config.Locale.invalid, 'error') end
    if treatment == 'revive' then
        local allowed = auth(src, 'revive')
        if not allowed then return end
    end
    if not target or target == src or not isNear(src, target, Config.Security.MaxTreatmentDistance) then
        return notify(src, Config.Locale.tooFar, 'error')
    end
    local targetPed = GetPlayerPed(target)
    if targetPed == 0 then return notify(src, Config.Locale.noTarget, 'error') end
    local targetHealth = GetEntityHealth(targetPed)
    if treatment == 'revive' and targetHealth > 101 then
        return notify(src, 'Deze patiënt is niet neergehaald; reanimatie is niet nodig.', 'error')
    elseif treatment ~= 'revive' and targetHealth <= 0 then
        return notify(src, 'Deze patiënt moet eerst worden gereanimeerd.', 'error')
    end
    if not THOOTJE_EMS.HasItem(src, definition.item, definition.count) then
        return notify(src, ('Je hebt %s nodig.'):format(definition.label), 'error')
    end
    if not THOOTJE_EMS.RemoveItem(src, definition.item, definition.count) then
        return notify(src, Config.Locale.noItem, 'error')
    end

    local patientName = THOOTJE_EMS.GetCharacterName(target)
    local medicName = THOOTJE_EMS.GetCharacterName(src)
    local treatmentLabel = ({ revive = 'Reanimatie', heal = 'Medische behandeling', stabilize = 'Stabiliseren' })[treatment] or treatment
    MySQL.insert.await([[
        INSERT INTO thootje_ems_treatments
        (medic_identifier, medic_name, patient_identifier, patient_name, treatment, item_name)
        VALUES (?,?,?,?,?,?)
    ]], {
        THOOTJE_EMS.GetIdentifier(src), medicName, THOOTJE_EMS.GetIdentifier(target),
        patientName, treatmentLabel, definition.item
    })
    TriggerClientEvent('thootje-ambulancejob:client:applyTreatment', target, treatment, Config.Treatment)
    TriggerClientEvent('thootje-ambulancejob:client:playTreatment', src, treatment)
    notify(src, Config.Locale.treated, 'success')
    notify(target, ('Je ontvangt medische hulp van %s.'):format(medicName), 'success')
    if treatment == 'revive' then
        TriggerClientEvent('thootje-ambulancejob:client:revived', target)
    end
    if treatment == 'stabilize' or treatment == 'heal' then
        TriggerClientEvent('thootje-ambulancejob:client:medicalStatus', target, treatment)
    end
    broadcastCallUpdate()
end)

RegisterNetEvent('thootje-ambulancejob:server:invoice', function(data)
    local src = source
    if not auth(src, 'invoice') or not rateOk(src, 'invoice') then return end
    if type(data) ~= 'table' then return end
    local target = tonumber(data.target)
    local amount = math.floor(tonumber(data.amount) or 0)
    local reason = tostring(data.reason or ''):gsub('[\r\n]', ' '):sub(1, 90)
    if not target or target == src or not isNear(src, target, Config.Security.MaxInvoiceDistance)
        or amount < Config.Security.MinInvoiceAmount or amount > Config.Security.MaxInvoiceAmount or #reason < 3 then
        return notify(src, Config.Locale.invalid, 'error')
    end
    local ok, invoiceId, invoiceNumber = THOOTJE_EMS.CreateInvoice(src, target, amount, 'Ambulancekosten: ' .. reason)
    if not ok then return notify(src, ('Factuur kon niet worden aangemaakt (%s).'):format(tostring(invoiceId)), 'error') end
    MySQL.insert.await([[
        INSERT INTO thootje_ems_treatments
        (medic_identifier, medic_name, patient_identifier, patient_name, treatment, item_name)
        VALUES (?,?,?,?,?,?)
    ]], {
        THOOTJE_EMS.GetIdentifier(src), 'Ambulancedienst',
        THOOTJE_EMS.GetIdentifier(target), THOOTJE_EMS.GetCharacterName(target),
        'Factuur ' .. tostring(invoiceNumber or invoiceId), 'billing'
    })
    notify(src, ('Factuur %s aangemaakt in THOOTJE-BILLING.'):format(tostring(invoiceNumber or invoiceId)), 'success')
    notify(target, 'Je hebt een factuur van de ambulancedienst ontvangen. Bekijk deze in THOOTJE-BILLING.', 'info')
    updateMedicTable(src)
end)

RegisterNetEvent('thootje-ambulancejob:server:spawnVehicle', function(index, stationIndex)
    local src = source
    local ok, grade = auth(src, 'garage')
    if not ok then return end
    index, stationIndex = tonumber(index), tonumber(stationIndex) or 1
    local station = Config.Stations[stationIndex]
    if not station or not index then return notify(src, Config.Locale.invalid, 'error') end
    local available = {}
    for _, vehicle in ipairs(Config.Vehicles) do
        if grade >= vehicle.minGrade then available[#available + 1] = vehicle end
    end
    local selected = available[index]
    if not selected then return notify(src, 'Dit voertuig is niet vrijgegeven voor jouw rang.', 'error') end
    local ped = GetPlayerPed(src)
    if ped == 0 or #(GetEntityCoords(ped) - station.garage) > 20.0 then
        return notify(src, 'Je moet bij de dienstgarage staan.', 'error')
    end
    TriggerClientEvent('thootje-ambulancejob:client:spawnVehicle', src, selected.model, station.spawn)
end)

RegisterNetEvent('thootje-ambulancejob:server:requestGarage', function(stationIndex)
    local src = source
    local ok, grade = auth(src, 'garage')
    if not ok then return end
    stationIndex = tonumber(stationIndex) or 1
    local station = Config.Stations[stationIndex]
    if not station then return end
    local available = {}
    for _, vehicle in ipairs(Config.Vehicles) do
        if grade >= vehicle.minGrade then available[#available + 1] = vehicle end
    end
    TriggerClientEvent('thootje-ambulancejob:client:garageList', src, available, stationIndex)
end)

RegisterNetEvent('thootje-ambulancejob:server:panic', function()
    local src = source
    if not auth(src, 'tablet') then return end
    local name = THOOTJE_EMS.GetCharacterName(src)
    for _, player in ipairs(GetPlayers()) do
        local id = tonumber(player)
        local job = THOOTJE_EMS.GetJob(id)
        if job and job.name == Config.JobName and job.onduty then
            notify(id, ('PANIEKMELDING: %s heeft directe assistentie nodig!'):format(name), 'error')
        end
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    actionCooldown[tostring(src) .. ':treat'] = nil
    actionCooldown[tostring(src) .. ':invoice'] = nil
    MySQL.update('UPDATE thootje_ems_calls SET status="open", assigned_identifier=NULL, assigned_name=NULL, assigned_source=NULL, updated_at=NOW() WHERE assigned_source=? AND status="assigned"', { src })
end)

exports('GetOnDutyMedics', function()
    local result = {}
    for _, medic in ipairs(roster()) do if medic.onduty then result[#result + 1] = medic end end
    return result
end)

exports('IsOnDutyMedic', function(src)
    local job = THOOTJE_EMS.GetJob(src)
    return job ~= nil and job.name == Config.JobName and job.onduty == true
end)
