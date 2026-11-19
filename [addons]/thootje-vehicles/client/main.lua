local uiOpen = false
local lastLock = 0

local function notify(message)
    TriggerEvent(Config.Notifications.event, message, Config.Notifications.type)
end

local function cleanPlate(value)
    return tostring(value or ''):gsub('^%s*(.-)%s*$', '%1'):upper()
end

local function vehicleForLock()
    local ped = PlayerPedId()
    local current = GetVehiclePedIsIn(ped, false)
    if current ~= 0 and (Config.AllowPassengersToLock or GetPedInVehicleSeat(current, -1) == ped) then
        return current
    end
    local coords = GetEntityCoords(ped)
    local vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, Config.LockDistance, 0, 70)
    if vehicle ~= 0 then return vehicle end
    return 0
end

local function toggleVehicleLock()
    if GetGameTimer() - lastLock < Config.LockCooldownMs then return end
    lastLock = GetGameTimer()
    local vehicle = vehicleForLock()
    if vehicle == 0 then return notify('Geen voertuig in de buurt.') end
    local plate = cleanPlate(GetVehicleNumberPlateText(vehicle))
    TriggerServerEvent('thootje-vehicles:server:checkLock', plate, VehToNet(vehicle))
end

RegisterCommand(Config.OpenCommand, function()
    if uiOpen then return end
    TriggerServerEvent('thootje-vehicles:server:requestKeys')
end, false)
RegisterKeyMapping(Config.OpenCommand, 'Autosleutels beheren', 'keyboard', Config.OpenKey)

RegisterCommand(Config.LockCommand, toggleVehicleLock, false)
RegisterKeyMapping(Config.LockCommand, 'Voertuig vergrendelen / ontgrendelen', 'keyboard', Config.LockKey)

RegisterNetEvent('thootje-vehicles:client:notify', notify)

RegisterNetEvent('thootje-vehicles:client:open', function(keys)
    uiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', keys = keys })
end)

RegisterNetEvent('thootje-vehicles:client:update', function(keys)
    SendNUIMessage({ action = 'update', keys = keys })
end)

RegisterNetEvent('thootje-vehicles:client:toggleLock', function(netId)
    local vehicle = NetToVeh(tonumber(netId) or 0)
    if vehicle == 0 or not DoesEntityExist(vehicle) then return notify('Voertuig niet meer beschikbaar.') end
    local current = GetVehicleDoorLockStatus(vehicle)
    local locked = current == 2 or current == 3 or current == 4 or current == 5
    local newState = locked and 1 or 2
    SetVehicleDoorsLocked(vehicle, newState)
    SetVehicleDoorsLockedForAllPlayers(vehicle, not locked)
    if Config.LockFlash then
        SetVehicleLights(vehicle, 2)
        Wait(180)
        SetVehicleLights(vehicle, 0)
        Wait(120)
        SetVehicleLights(vehicle, 2)
        Wait(180)
        SetVehicleLights(vehicle, 0)
    end
    if Config.LockSound then
        PlaySoundFrontend(-1, locked and 'Remote_Control_Open' or 'Remote_Control_Close', 'PI_Menu_Sounds', true)
    end
    notify(locked and 'Voertuig ontgrendeld.' or 'Voertuig vergrendeld.')
end)

RegisterNetEvent('thootje-vehicles:client:keyAccess', function(plate, allowed)
    if not allowed then notify('Je hebt geen sleutels van ' .. plate .. '.') end
end)

RegisterNetEvent('thootje-vehicles:client:sharedList', function(plate, rows)
    SendNUIMessage({ action = 'shared', plate = plate, holders = rows })
end)

RegisterNUICallback('close', function(_, cb)
    uiOpen = false
    SetNuiFocus(false, false)
    cb({ ok = true })
end)

RegisterNUICallback('share', function(data, cb)
    TriggerServerEvent('thootje-vehicles:server:shareKey', tonumber(data.target), cleanPlate(data.plate))
    cb({ ok = true })
end)

RegisterNUICallback('revoke', function(data, cb)
    TriggerServerEvent('thootje-vehicles:server:revokeKey', tostring(data.identifier), cleanPlate(data.plate))
    cb({ ok = true })
end)

RegisterNUICallback('shared', function(data, cb)
    TriggerServerEvent('thootje-vehicles:server:getShared', cleanPlate(data.plate))
    cb({ ok = true })
end)

RegisterNUICallback('refresh', function(_, cb)
    TriggerServerEvent('thootje-vehicles:server:requestKeys')
    cb({ ok = true })
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then SetNuiFocus(false, false) end
end)
