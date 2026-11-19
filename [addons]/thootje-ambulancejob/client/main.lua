local tabletOpen = false
local currentStation = 1

local function notify(message, kind)
    TriggerEvent('chat:addMessage', { color = { 40, 190, 170 }, args = { 'THOOTJE EMS', message } })
end

local function nearestPlayer(maxDistance)
    local me = PlayerId()
    local origin = GetEntityCoords(PlayerPedId())
    local best, bestDistance
    for _, player in ipairs(GetActivePlayers()) do
        if player ~= me then
            local ped = GetPlayerPed(player)
            local distance = #(GetEntityCoords(ped) - origin)
            if distance <= maxDistance and (not bestDistance or distance < bestDistance) then
                best, bestDistance = GetPlayerServerId(player), distance
            end
        end
    end
    return best
end

local function openTablet()
    TriggerServerEvent('thootje-ambulancejob:server:openTablet')
end

RegisterNetEvent('thootje-ambulancejob:client:requestOpen', openTablet)
RegisterNetEvent('thootje-ambulancejob:client:requestDuty', function()
    TriggerServerEvent('thootje-ambulancejob:server:toggleDuty')
end)

RegisterCommand(Config.OpenCommand, openTablet, false)
RegisterKeyMapping(Config.OpenCommand, 'Open ambulancedienst MDT', 'keyboard', Config.Key)
RegisterCommand(Config.DutyCommand, function() TriggerServerEvent('thootje-ambulancejob:server:toggleDuty') end, false)
RegisterCommand('emspanic', function() TriggerServerEvent('thootje-ambulancejob:server:panic') end, false)
RegisterCommand('emsrevive', function(_, args)
    local target = tonumber(args[1]) or nearestPlayer(3.5)
    if target then TriggerServerEvent('thootje-ambulancejob:server:treat', target, 'revive') else notify('Geen patiënt in de buurt.') end
end, false)
RegisterCommand('emsheal', function(_, args)
    local target = tonumber(args[1]) or nearestPlayer(3.5)
    if target then TriggerServerEvent('thootje-ambulancejob:server:treat', target, 'heal') else notify('Geen patiënt in de buurt.') end
end, false)
RegisterCommand('emsstabilize', function(_, args)
    local target = tonumber(args[1]) or nearestPlayer(3.5)
    if target then TriggerServerEvent('thootje-ambulancejob:server:treat', target, 'stabilize') else notify('Geen patiënt in de buurt.') end
end, false)
RegisterCommand('emsgarage', function(_, args)
    TriggerServerEvent('thootje-ambulancejob:server:requestGarage', tonumber(args[1]) or currentStation)
end, false)

RegisterCommand(Config.CallCommand, function(_, args)
    local message = table.concat(args, ' ')
    if message == '' then message = 'Ik heb medische hulp nodig.' end
    local coords = GetEntityCoords(PlayerPedId())
    TriggerServerEvent('thootje-ambulancejob:server:createCall', 'medical', message, { x = coords.x, y = coords.y, z = coords.z })
end, false)

RegisterNetEvent('thootje-ambulancejob:client:openTablet', function(data, nearby)
    tabletOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', data = data or {}, nearby = nearby or {} })
end)

RegisterNetEvent('thootje-ambulancejob:client:update', function(data)
    SendNUIMessage({ action = 'update', data = data or {} })
end)

RegisterNetEvent('thootje-ambulancejob:client:nearby', function(nearby)
    SendNUIMessage({ action = 'nearby', nearby = nearby or {} })
end)

RegisterNetEvent('thootje-ambulancejob:client:setWaypoint', function(x, y, z)
    SetNewWaypoint(tonumber(x) + 0.0, tonumber(y) + 0.0)
    notify('Route naar de 112-melding is ingesteld.')
end)

RegisterNetEvent('thootje-ambulancejob:client:notify', function(message, kind)
    notify(message, kind)
end)

RegisterNUICallback('close', function(_, cb)
    tabletOpen = false
    SetNuiFocus(false, false)
    cb({ ok = true })
end)

RegisterNUICallback('refresh', function(_, cb)
    TriggerServerEvent('thootje-ambulancejob:server:refresh')
    cb({ ok = true })
end)

RegisterNUICallback('nearby', function(_, cb)
    TriggerServerEvent('thootje-ambulancejob:server:nearby')
    cb({ ok = true })
end)

RegisterNUICallback('acceptCall', function(data, cb)
    TriggerServerEvent('thootje-ambulancejob:server:acceptCall', data.id)
    cb({ ok = true })
end)

RegisterNUICallback('completeCall', function(data, cb)
    TriggerServerEvent('thootje-ambulancejob:server:completeCall', data.id)
    cb({ ok = true })
end)

RegisterNUICallback('treat', function(data, cb)
    TriggerServerEvent('thootje-ambulancejob:server:treat', data.target, data.treatment)
    cb({ ok = true })
end)

RegisterNUICallback('invoice', function(data, cb)
    TriggerServerEvent('thootje-ambulancejob:server:invoice', data)
    cb({ ok = true })
end)

RegisterNUICallback('panic', function(_, cb)
    TriggerServerEvent('thootje-ambulancejob:server:panic')
    cb({ ok = true })
end)

RegisterNUICallback('garage', function(_, cb)
    TriggerServerEvent('thootje-ambulancejob:server:requestGarage', currentStation)
    cb({ ok = true })
end)

RegisterNUICallback('spawnVehicle', function(data, cb)
    TriggerServerEvent('thootje-ambulancejob:server:spawnVehicle', data.index, data.station)
    cb({ ok = true })
end)

RegisterNetEvent('thootje-ambulancejob:client:garageList', function(vehicles, station)
    SendNUIMessage({ action = 'garage', vehicles = vehicles or {}, station = station })
    if tabletOpen then return end
    local labels = {}
    for i, vehicle in ipairs(vehicles or {}) do labels[#labels + 1] = ('%s: %s'):format(i, vehicle.label) end
    notify('Dienstgarage: ' .. table.concat(labels, ' | '))
end)

RegisterNetEvent('thootje-ambulancejob:client:spawnVehicle', function(model, spawn)
    local hash = joaat(model)
    if not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then return notify('Voertuigmodel bestaat niet.') end
    RequestModel(hash)
    local timeout = GetGameTimer() + 8000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do Wait(10) end
    if not HasModelLoaded(hash) then return notify('Voertuig kon niet worden geladen.') end
    local vehicle = CreateVehicle(hash, spawn.x, spawn.y, spawn.z, spawn.w, true, false)
    if vehicle == 0 then return notify('Voertuig kon niet worden gespawned.') end
    SetVehicleNumberPlateText(vehicle, ('EMS%04d'):format(GetPlayerServerId(PlayerId()) % 10000))
    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehicleDirtLevel(vehicle, 0.0)
    TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
    SetModelAsNoLongerNeeded(hash)
end)

RegisterNetEvent('thootje-ambulancejob:client:playTreatment', function(treatment)
    local ped = PlayerPedId()
    local dict, anim = 'amb@medic@standing@tendtodead@base', 'base'
    if treatment == 'revive' then dict, anim = 'mini@cpr@char_a@cpr_str', 'cpr_pumpchest' end
    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 5000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < timeout do Wait(10) end
    if HasAnimDictLoaded(dict) then TaskPlayAnim(ped, dict, anim, 8.0, -8.0, treatment == 'revive' and 8000 or 4500, 1, 0, false, false, false) end
end)

RegisterNetEvent('thootje-ambulancejob:client:applyTreatment', function(treatment, settings)
    local ped = PlayerPedId()
    if treatment == 'revive' then
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)
        NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, true, false)
        ClearPedTasksImmediately(ped)
        SetEntityHealth(ped, settings.reviveHealth or 150)
        ClearPedBloodDamage(ped)
        SetPlayerInvincible(PlayerId(), false)
        TriggerEvent('thootje-ambulancejob:client:notify', 'Je bent gereanimeerd.', 'success')
    elseif treatment == 'heal' then
        local health = GetEntityHealth(ped)
        if health > 0 then SetEntityHealth(ped, math.min(GetEntityMaxHealth(ped), health + (settings.healAmount or 45))) end
    elseif treatment == 'stabilize' then
        local health = GetEntityHealth(ped)
        if health > 0 then SetEntityHealth(ped, math.max(health, settings.stabilizeHealth or 110)) end
    end
end)

RegisterNetEvent('thootje-ambulancejob:client:revived', function()
    TriggerEvent('thootje-ambulancejob:client:notify', 'Reanimatie uitgevoerd.', 'success')
end)

RegisterNetEvent('thootje-ambulancejob:client:medicalStatus', function(treatment)
    if treatment == 'stabilize' then
        TriggerEvent('thootje-ambulancejob:client:notify', 'Je toestand is gestabiliseerd.', 'success')
    end
end)

CreateThread(function()
    for _, station in ipairs(Config.Stations) do
        if Config.Blips.enabled then
            local blip = AddBlipForCoord(station.coords.x, station.coords.y, station.coords.z)
            SetBlipSprite(blip, Config.Blips.sprite)
            SetBlipColour(blip, Config.Blips.color)
            SetBlipScale(blip, Config.Blips.scale)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString(station.label)
            EndTextCommandSetBlipName(blip)
        end
    end

    while true do
        local wait = 1200
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        for index, station in ipairs(Config.Stations) do
            local dutyDistance = #(coords - station.duty)
            local garageDistance = #(coords - station.garage)
            if dutyDistance < 15.0 or garageDistance < 15.0 then
                wait = 0
                DrawMarker(2, station.duty.x, station.duty.y, station.duty.z + 0.15, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.28, 0.28, 0.18, 40, 190, 170, 180, false, true, 2, false, nil, nil, false)
                DrawMarker(2, station.garage.x, station.garage.y, station.garage.z + 0.15, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.28, 0.28, 0.18, 40, 190, 170, 180, false, true, 2, false, nil, nil, false)
                if dutyDistance < 1.5 then
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName('Druk op ~INPUT_CONTEXT~ om in/uit dienst te gaan')
                    EndTextCommandDisplayHelp(0, false, true, -1)
                    if IsControlJustReleased(0, 38) then TriggerServerEvent('thootje-ambulancejob:server:toggleDuty') end
                elseif garageDistance < 1.5 then
                    currentStation = index
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName('Druk op ~INPUT_CONTEXT~ voor de ambulancedienstgarage')
                    EndTextCommandDisplayHelp(0, false, true, -1)
                    if IsControlJustReleased(0, 38) then TriggerServerEvent('thootje-ambulancejob:server:requestGarage', index) end
                end
            end
        end
        if tabletOpen and IsControlJustReleased(0, 200) then
            tabletOpen = false
            SetNuiFocus(false, false)
            SendNUIMessage({ action = 'close' })
        end
        Wait(wait)
    end
end)
