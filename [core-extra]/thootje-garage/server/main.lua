local function notify(src, msg) TriggerClientEvent('thootje-garage:client:notify', src, msg) end
local function identifier(src) return Config.Identifier(src) end

local function getGarage(id) return Garages[tostring(id or '')] end
local function nearGarage(src, id, maxDistance)
    local garage = getGarage(id)
    if not garage then return false end
    local ped = GetPlayerPed(src)
    if ped == 0 then return false end
    local coords = GetEntityCoords(ped)
    return #(coords - garage.coords) <= (maxDistance or Config.OpenDistance)
end

local function decodeVehicle(row)
    local ok, data = pcall(json.decode, row.vehicle_data or '{}')
    if not ok or type(data) ~= 'table' then data = {} end
    return {
        id = row.id, plate = row.plate, model = row.model, label = row.vehicle_label,
        vehicleType = row.vehicle_type, garage = row.garage, stored = tonumber(row.stored) == 1,
        impounded = tonumber(row.impounded) == 1, nickname = row.nickname, data = data
    }
end

local function listVehicles(src, garageId)
    local owner = identifier(src)
    if not owner then return {} end
    local rows = MySQL.query.await('SELECT * FROM thootje_garage_vehicles WHERE owner = ? ORDER BY vehicle_label ASC', { owner })
    local vehicles = {}
    for _, row in ipairs(rows or {}) do
        local v = decodeVehicle(row)
        v.availableHere = v.garage == garageId and v.stored and not v.impounded
        v.garageLabel = Garages[v.garage] and Garages[v.garage].label or 'Onbekende garage'
        vehicles[#vehicles + 1] = v
    end
    return vehicles
end

local function sendGarage(src, garageId, opening)
    local garage = getGarage(garageId)
    if not garage then return end
    local payload = {
        garageId = garageId, garageLabel = garage.label, garageType = garage.type,
        vehicles = listVehicles(src, garageId),
        impoundFee = Config.Impound.fee
    }
    TriggerClientEvent(opening and 'thootje-garage:client:open' or 'thootje-garage:client:update', src, payload)
end

local function ownedVehicle(src, vehicleId)
    return MySQL.single.await('SELECT * FROM thootje_garage_vehicles WHERE id = ? AND owner = ?', { vehicleId, identifier(src) or 'none' })
end

RegisterNetEvent('thootje-garage:server:open', function(garageId)
    local src = source
    if not nearGarage(src, garageId, Config.OpenDistance) then return notify(src, 'Je bent te ver van deze garage.') end
    sendGarage(src, garageId, true)
end)

RegisterNetEvent('thootje-garage:server:refresh', function(garageId)
    local src = source
    if not nearGarage(src, garageId, Config.OpenDistance) then return end
    sendGarage(src, garageId, false)
end)

RegisterNetEvent('thootje-garage:server:takeOut', function(vehicleId, garageId)
    local src = source
    vehicleId = tonumber(vehicleId)
    local garage = getGarage(garageId)
    if not vehicleId or not garage or garage.type == 'impound' then return notify(src, 'Ongeldige garage of voertuig.') end
    if not nearGarage(src, garageId, Config.OpenDistance) then return notify(src, 'Je bent te ver van de garage.') end
    local row = ownedVehicle(src, vehicleId)
    if not row then return notify(src, 'Dit voertuig is niet van jou.') end
    if row.garage ~= garageId then return notify(src, 'Dit voertuig staat in: ' .. (Garages[row.garage] and Garages[row.garage].label or row.garage)) end
    if tonumber(row.impounded) == 1 then return notify(src, 'Dit voertuig staat in beslagname.') end
    if tonumber(row.stored) ~= 1 then return notify(src, 'Dit voertuig is al buiten de garage.') end

    local changed = MySQL.update.await('UPDATE thootje_garage_vehicles SET stored = 0 WHERE id = ? AND owner = ? AND stored = 1 AND impounded = 0', { vehicleId, identifier(src) })
    if changed ~= 1 then return notify(src, 'Voertuig kon niet worden uitgegeven.') end
    local vehicle = decodeVehicle(row)
    TriggerClientEvent('thootje-garage:client:spawn', src, vehicle, garage.spawn)
    sendGarage(src, garageId, false)
end)

RegisterNetEvent('thootje-garage:server:spawnFailed', function(plate)
    local src = source
    MySQL.update.await('UPDATE thootje_garage_vehicles SET stored = 1 WHERE plate = ? AND owner = ?', { tostring(plate), identifier(src) or 'none' })
end)

RegisterNetEvent('thootje-garage:server:spawned', function(plate, netId)
    local src = source
    local row = MySQL.single.await('SELECT id FROM thootje_garage_vehicles WHERE plate = ? AND owner = ?', { tostring(plate), identifier(src) or 'none' })
    if not row then return end
    TriggerClientEvent('thootje-garage:client:notify', src, 'Voertuig uitgegeven. Veel rijplezier!')
end)

RegisterNetEvent('thootje-garage:server:store', function(rawPlate, garageId, props, netId)
    local src = source
    if not nearGarage(src, garageId, Config.InteractDistance + 2.0) then return notify(src, 'Je bent niet bij een garage.') end
    local plate = tostring(rawPlate or ''):gsub('^%s*(.-)%s*$', '%1'):upper()
    if plate == '' or #plate > 12 then return notify(src, 'Ongeldig kenteken.') end

    -- Controleer server-side dat de speler daadwerkelijk bestuurder is van
    -- het voertuig waarvan het kenteken wordt opgeslagen.
    local vehicleEntity = NetworkGetEntityFromNetworkId(tonumber(netId) or 0)
    local playerPed = GetPlayerPed(src)
    if not vehicleEntity or vehicleEntity == 0 or not DoesEntityExist(vehicleEntity) or playerPed == 0 then
        return notify(src, 'Voertuig kon niet server-side worden gecontroleerd.')
    end
    if GetPedInVehicleSeat(vehicleEntity, -1) ~= playerPed then
        return notify(src, 'Je moet bestuurder zijn van dit voertuig.')
    end
    local entityPlate = tostring(GetVehicleNumberPlateText(vehicleEntity) or ''):gsub('^%s*(.-)%s*$', '%1'):upper()
    if entityPlate ~= plate then return notify(src, 'Kentekencontrole mislukt.') end

    local row = MySQL.single.await('SELECT * FROM thootje_garage_vehicles WHERE plate = ? AND owner = ?', { plate, identifier(src) or 'none' })
    if not row then return notify(src, 'Dit voertuig staat niet op jouw naam.') end
    if tonumber(row.stored) == 1 then return notify(src, 'Dit voertuig staat al in de garage.') end
    if type(props) ~= 'table' then props = {} end
    local clean = {
        fuel = math.max(0, math.min(100, tonumber(props.fuel) or Config.VehicleDefaults.fuel)),
        engine = math.max(0, math.min(1000, tonumber(props.engine) or Config.VehicleDefaults.engine)),
        body = math.max(0, math.min(1000, tonumber(props.body) or Config.VehicleDefaults.body)),
        dirt = math.max(0, math.min(15, tonumber(props.dirt) or 0)),
        props = type(props.props) == 'table' and props.props or {}
    }
    local encoded = json.encode(clean)
    local changed = MySQL.update.await('UPDATE thootje_garage_vehicles SET vehicle_data = ?, garage = ?, stored = 1 WHERE id = ? AND owner = ? AND stored = 0', { encoded, garageId, row.id, identifier(src) })
    if changed ~= 1 then return notify(src, 'Opslaan van voertuig is mislukt.') end

    local entity = NetworkGetEntityFromNetworkId(tonumber(netId) or 0)
    if entity and entity ~= 0 and DoesEntityExist(entity) then DeleteEntity(entity) end
    notify(src, 'Voertuig veilig opgeslagen.')
    sendGarage(src, garageId, false)
end)

RegisterNetEvent('thootje-garage:server:releaseImpound', function(vehicleId, garageId)
    local src = source
    local garage = getGarage(garageId)
    if not Config.Impound.enabled or not garage or garage.type ~= 'impound' then return notify(src, 'Je staat niet bij de inbeslagname.') end
    if not nearGarage(src, garageId, Config.OpenDistance) then return notify(src, 'Je bent te ver van de inbeslagname.') end
    local row = ownedVehicle(src, tonumber(vehicleId))
    if not row or tonumber(row.impounded) ~= 1 then return notify(src, 'Dit voertuig staat niet in beslagname.') end

    local fee = math.floor(tonumber(Config.Impound.fee) or 0)
    if fee > 0 then
        if GetResourceState(Config.BankingResource) ~= 'started' then return notify(src, 'Banking-resource is niet gestart.') end
        local ok, result = pcall(function()
            return exports[Config.BankingResource][Config.Impound.bankExport](src, fee)
        end)
        if not ok or result == false then return notify(src, 'Betaling mislukt. Controleer je banksaldo.') end
    end

    MySQL.update.await('UPDATE thootje_garage_vehicles SET impounded = 0, stored = 1, garage = ? WHERE id = ? AND owner = ?', { 'legion', row.id, identifier(src) })
    notify(src, ('Voertuig vrijgegeven voor €%s. Haal het op bij Legion Square Garage.'):format(fee))
    sendGarage(src, garageId, false)
end)

RegisterNetEvent('thootje-garage:server:rename', function(vehicleId, nickname)
    local src = source
    local row = ownedVehicle(src, tonumber(vehicleId))
    if not row then return notify(src, 'Voertuig niet gevonden.') end
    nickname = tostring(nickname or ''):sub(1, 32)
    MySQL.update.await('UPDATE thootje_garage_vehicles SET nickname = ? WHERE id = ? AND owner = ?', { nickname ~= '' and nickname or nil, row.id, identifier(src) })
    notify(src, 'Voertuignaam opgeslagen.')
    local garageId = row.garage
    if nearGarage(src, garageId, Config.OpenDistance) then sendGarage(src, garageId, false) end
end)

RegisterCommand('givevehicle', function(src, args)
    if src ~= 0 and not IsPlayerAceAllowed(src, Config.AdminAce) then return notify(src, 'Geen toestemming.') end
    local target, model = tonumber(args[1]), tostring(args[2] or ''):lower()
    local plate = tostring(args[3] or ''):upper()
    if not target or not GetPlayerName(target) or model == '' then
        local msg = 'Gebruik: givevehicle [id] [model] [kenteken]'
        if src == 0 then print(msg) else notify(src, msg) end
        return
    end
    if plate == '' then plate = ('NW%05d'):format(math.random(0, 99999)) end
    plate = plate:sub(1, 8)
    local owner = identifier(target)
    if not owner then return end
    local count = MySQL.scalar.await('SELECT COUNT(*) FROM thootje_garage_vehicles WHERE owner = ?', { owner }) or 0
    if count >= Config.MaxVehiclesPerPlayer then return notify(src, 'Deze speler heeft het maximale aantal voertuigen.') end
    local exists = MySQL.scalar.await('SELECT COUNT(*) FROM thootje_garage_vehicles WHERE plate = ?', { plate }) or 0
    if exists > 0 then return notify(src, 'Dit kenteken bestaat al.') end
    local data = { fuel = 100.0, engine = 1000.0, body = 1000.0, dirt = 0, props = {} }
    MySQL.insert.await('INSERT INTO thootje_garage_vehicles (owner, plate, model, vehicle_label, vehicle_data, garage, stored) VALUES (?, ?, ?, ?, ?, ?, 1)', { owner, plate, model, model, json.encode(data), 'legion' })
    notify(target, ('Je hebt een voertuig ontvangen: %s (%s).'):format(model, plate))
    if src ~= 0 then notify(src, 'Voertuig toegevoegd.') else print('Voertuig toegevoegd aan speler ' .. target) end
end, false)

RegisterCommand('impoundvehicle', function(src, args)
    if src ~= 0 and not IsPlayerAceAllowed(src, Config.AdminAce) then return notify(src, 'Geen toestemming.') end
    local plate = tostring(args[1] or ''):upper()
    if plate == '' then return end
    local changed = MySQL.update.await('UPDATE thootje_garage_vehicles SET impounded = 1, stored = 1 WHERE plate = ?', { plate })
    local msg = changed == 1 and ('Voertuig ' .. plate .. ' in beslag genomen.') or 'Kenteken niet gevonden.'
    if src == 0 then print(msg) else notify(src, msg) end
end, false)

exports('AddVehicle', function(ownerIdentifier, model, plate, label, garageId, vehicleData)
    if not ownerIdentifier or not model or not plate then return false end
    garageId = getGarage(garageId) and garageId or 'legion'
    local data = vehicleData or { fuel = 100, engine = 1000, body = 1000, dirt = 0, props = {} }
    local ok = pcall(function()
        MySQL.insert.await('INSERT INTO thootje_garage_vehicles (owner, plate, model, vehicle_label, vehicle_data, garage, stored) VALUES (?, ?, ?, ?, ?, ?, 1)', {
            tostring(ownerIdentifier), tostring(plate):upper():sub(1, 12), tostring(model), tostring(label or model), json.encode(data), garageId
        })
    end)
    return ok
end)

exports('GetOwnedVehicles', function(ownerIdentifier)
    local rows = MySQL.query.await('SELECT * FROM thootje_garage_vehicles WHERE owner = ?', { tostring(ownerIdentifier) })
    local result = {}
    for _, row in ipairs(rows or {}) do result[#result + 1] = decodeVehicle(row) end
    return result
end)

exports('SetVehicleImpounded', function(plate, state)
    local changed = MySQL.update.await('UPDATE thootje_garage_vehicles SET impounded = ?, stored = 1 WHERE plate = ?', { state and 1 or 0, tostring(plate):upper() })
    return changed == 1
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        print('^2[thootje-garage] gestart. Importeer sql/thootje_garage.sql en controleer Config.Identifier.^0')
    end
end)
