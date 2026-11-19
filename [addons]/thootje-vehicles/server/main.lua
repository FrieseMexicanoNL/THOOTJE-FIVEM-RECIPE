local lastAction = {}

local function identifier(src)
    return Config.Identifier(src)
end

local function notify(src, message)
    TriggerClientEvent('thootje-vehicles:client:notify', src, message)
end

local function cleanPlate(value)
    return tostring(value or ''):gsub('^%s*(.-)%s*$', '%1'):upper():sub(1, 12)
end

local function ownedVehicle(src, plate)
    local owner = identifier(src)
    if not owner then return nil end
    return MySQL.single.await(
        'SELECT id, owner, plate, model, vehicle_label FROM thootje_garage_vehicles WHERE plate = ? AND owner = ?',
        { cleanPlate(plate), owner }
    )
end

local function getVehicleOwner(plate)
    return MySQL.single.await(
        'SELECT owner, plate, model, vehicle_label FROM thootje_garage_vehicles WHERE plate = ?',
        { cleanPlate(plate) }
    )
end

local function hasKeyIdentifier(holder, plate)
    local vehicle = getVehicleOwner(plate)
    if not vehicle then return false end
    if vehicle.owner == holder then return true end
    local row = MySQL.single.await(
        'SELECT id FROM thootje_vehicle_keys WHERE plate = ? AND holder_identifier = ? AND owner_identifier = ?',
        { cleanPlate(plate), holder, vehicle.owner }
    )
    return row ~= nil
end

local function hasKey(src, plate)
    local id = identifier(src)
    if not id then return false end
    return hasKeyIdentifier(id, plate)
end

local function getPlayerKeys(src)
    local id = identifier(src)
    if not id then return {} end
    local rows = MySQL.query.await([[
        SELECT k.plate, k.holder_name, k.created_at, v.model, v.vehicle_label, v.owner
        FROM thootje_vehicle_keys k
        LEFT JOIN thootje_garage_vehicles v ON v.plate = k.plate
        WHERE k.holder_identifier = ?
        ORDER BY k.created_at DESC
    ]], { id }) or {}
    local result = {}
    for _, row in ipairs(rows) do
        result[#result + 1] = {
            plate = row.plate,
            model = row.model or 'Onbekend',
            label = row.vehicle_label or row.model or 'Voertuig',
            holderName = row.holder_name,
            isOwner = row.owner == id
        }
    end

    local owned = MySQL.query.await(
        'SELECT plate, model, vehicle_label FROM thootje_garage_vehicles WHERE owner = ? ORDER BY vehicle_label',
        { id }
    ) or {}
    local seen = {}
    for _, item in ipairs(result) do seen[item.plate] = true end
    for _, row in ipairs(owned) do
        if not seen[row.plate] then
            result[#result + 1] = {
                plate = row.plate, model = row.model,
                label = row.vehicle_label or row.model,
                holderName = 'Eigenaar', isOwner = true
            }
        end
    end
    return result
end

local function sendKeys(src)
    TriggerClientEvent('thootje-vehicles:client:open', src, getPlayerKeys(src))
end

local function cooldown(src, key)
    local now = GetGameTimer()
    local token = tostring(src) .. ':' .. key
    if lastAction[token] and now - lastAction[token] < Config.LockCooldownMs then return false end
    lastAction[token] = now
    return true
end

RegisterNetEvent('thootje-vehicles:server:requestKeys', function()
    sendKeys(source)
end)

RegisterNetEvent('thootje-vehicles:server:shareKey', function(target, rawPlate)
    local src = source
    target = tonumber(target)
    local plate = cleanPlate(rawPlate)
    if not target or target == src or not GetPlayerName(target) then return notify(src, 'Speler niet gevonden.') end
    if not cooldown(src, 'share') then return end

    local ownerVehicle = ownedVehicle(src, plate)
    if not ownerVehicle then return notify(src, 'Alleen de voertuigeigenaar kan sleutels uitdelen.') end

    local srcPed, targetPed = GetPlayerPed(src), GetPlayerPed(target)
    if srcPed == 0 or targetPed == 0 or #(GetEntityCoords(srcPed) - GetEntityCoords(targetPed)) > Config.ShareDistance then
        return notify(src, 'Deze speler staat niet dichtbij genoeg.')
    end

    local count = MySQL.scalar.await(
        'SELECT COUNT(*) FROM thootje_vehicle_keys WHERE plate = ? AND owner_identifier = ?',
        { plate, identifier(src) }
    ) or 0
    if count >= Config.MaxSharedKeysPerVehicle then return notify(src, 'Dit voertuig heeft het maximale aantal gedeelde sleutels.') end

    local targetId = identifier(target)
    if not targetId then return notify(src, 'Speleridentificatie kon niet worden gelezen.') end
    if targetId == identifier(src) then return notify(src, 'Je bent al eigenaar.') end

    local existing = MySQL.single.await(
        'SELECT id FROM thootje_vehicle_keys WHERE plate = ? AND holder_identifier = ?',
        { plate, targetId }
    )
    if existing then return notify(src, 'Deze speler heeft al een sleutel.') end

    MySQL.insert.await([[
        INSERT INTO thootje_vehicle_keys
        (plate, owner_identifier, holder_identifier, holder_name, granted_by)
        VALUES (?, ?, ?, ?, ?)
    ]], { plate, identifier(src), targetId, Config.PlayerName(target), identifier(src) })

    notify(src, ('Sleutel voor %s gedeeld met %s.'):format(plate, Config.PlayerName(target)))
    notify(target, ('Je hebt een autosleutel ontvangen voor %s.'):format(plate))
    sendKeys(src)
end)

RegisterNetEvent('thootje-vehicles:server:revokeKey', function(targetIdentifier, rawPlate)
    local src = source
    local plate = cleanPlate(rawPlate)
    local ownerVehicle = ownedVehicle(src, plate)
    if not ownerVehicle then return notify(src, 'Alleen de eigenaar kan gedeelde sleutels intrekken.') end
    local changed = MySQL.update.await(
        'DELETE FROM thootje_vehicle_keys WHERE plate = ? AND owner_identifier = ? AND holder_identifier = ?',
        { plate, identifier(src), tostring(targetIdentifier or '') }
    )
    if changed > 0 then
        notify(src, 'Gedeelde sleutel ingetrokken.')
        sendKeys(src)
    else
        notify(src, 'Gedeelde sleutel niet gevonden.')
    end
end)

RegisterNetEvent('thootje-vehicles:server:getShared', function(rawPlate)
    local src = source
    local plate = cleanPlate(rawPlate)
    if not ownedVehicle(src, plate) then return notify(src, 'Alleen de eigenaar kan sleutelhouders bekijken.') end
    local rows = MySQL.query.await(
        'SELECT holder_identifier, holder_name, created_at FROM thootje_vehicle_keys WHERE plate = ? AND owner_identifier = ? ORDER BY created_at DESC',
        { plate, identifier(src) }
    ) or {}
    TriggerClientEvent('thootje-vehicles:client:sharedList', src, plate, rows)
end)

RegisterNetEvent('thootje-vehicles:server:checkLock', function(rawPlate, netId)
    local src = source
    local plate = cleanPlate(rawPlate)
    if not cooldown(src, 'lock') then return end
    if not hasKey(src, plate) then return notify(src, 'Je hebt geen sleutels van dit voertuig.') end

    local entity = NetworkGetEntityFromNetworkId(tonumber(netId) or 0)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return notify(src, 'Voertuig niet gevonden.') end
    local entityPlate = cleanPlate(GetVehicleNumberPlateText(entity))
    if entityPlate ~= plate then return notify(src, 'Kentekencontrole mislukt.') end

    local ped = GetPlayerPed(src)
    if ped == 0 or #(GetEntityCoords(ped) - GetEntityCoords(entity)) > Config.LockDistance then
        return notify(src, 'Je bent te ver van het voertuig.')
    end
    TriggerClientEvent('thootje-vehicles:client:toggleLock', src, netId)
end)

RegisterNetEvent('thootje-vehicles:server:checkKeyAccess', function(rawPlate)
    local src = source
    local plate = cleanPlate(rawPlate)
    TriggerClientEvent('thootje-vehicles:client:keyAccess', src, plate, hasKey(src, plate))
end)

RegisterCommand(Config.AdminGiveKeyCommand, function(src, args)
    if src ~= 0 and not IsPlayerAceAllowed(src, Config.AdminAce) then return notify(src, 'Geen toestemming.') end
    local target, plate = tonumber(args[1]), cleanPlate(args[2])
    if not target or not GetPlayerName(target) or plate == '' then
        local usage = ('Gebruik: %s [id] [kenteken]'):format(Config.AdminGiveKeyCommand)
        if src == 0 then print(usage) else notify(src, usage) end
        return
    end
    local vehicle = getVehicleOwner(plate)
    local targetId = identifier(target)
    if not vehicle or not targetId then
        if src == 0 then print('Voertuig of speler niet gevonden.') else notify(src, 'Voertuig of speler niet gevonden.') end
        return
    end
    if vehicle.owner == targetId then return notify(src, 'Deze speler is al eigenaar.') end
    MySQL.insert.await([[
        INSERT INTO thootje_vehicle_keys (plate, owner_identifier, holder_identifier, holder_name, granted_by)
        VALUES (?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE holder_name = VALUES(holder_name)
    ]], { plate, vehicle.owner, targetId, Config.PlayerName(target), 'admin' })
    notify(target, 'Je hebt een autosleutel ontvangen voor ' .. plate .. '.')
    if src ~= 0 then notify(src, 'Sleutel uitgegeven.') else print('Sleutel uitgegeven.') end
end, false)

exports('HasVehicleKey', function(src, plate)
    return hasKey(tonumber(src), cleanPlate(plate))
end)

exports('GiveVehicleKey', function(ownerIdentifier, targetIdentifier, plate, targetName)
    plate = cleanPlate(plate)
    local vehicle = getVehicleOwner(plate)
    if not vehicle or vehicle.owner ~= tostring(ownerIdentifier) then return false end
    local ok = pcall(function()
        MySQL.insert.await([[
            INSERT INTO thootje_vehicle_keys (plate, owner_identifier, holder_identifier, holder_name, granted_by)
            VALUES (?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE holder_name = VALUES(holder_name)
        ]], { plate, tostring(ownerIdentifier), tostring(targetIdentifier), tostring(targetName or 'Speler'), tostring(ownerIdentifier) })
    end)
    return ok
end)

exports('RemoveVehicleKey', function(ownerIdentifier, targetIdentifier, plate)
    local changed = MySQL.update.await(
        'DELETE FROM thootje_vehicle_keys WHERE plate = ? AND owner_identifier = ? AND holder_identifier = ?',
        { cleanPlate(plate), tostring(ownerIdentifier), tostring(targetIdentifier) }
    )
    return changed > 0
end)

exports('GetVehicleKeys', function(src)
    return getPlayerKeys(tonumber(src))
end)

AddEventHandler('playerDropped', function()
    local src = source
    for key in pairs(lastAction) do
        if key:sub(1, #tostring(src) + 1) == tostring(src) .. ':' then lastAction[key] = nil end
    end
end)

print('^2[thootje-vehicles] Voertuigbezit en sleutels geladen.^0')
