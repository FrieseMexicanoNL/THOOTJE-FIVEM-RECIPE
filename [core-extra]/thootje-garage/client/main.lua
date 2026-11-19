local uiOpen = false
local currentGarage = nil
local spawnedVehicles = {}

local function notify(message)
    TriggerEvent('thootje-core:client:notify', message, 'info')
end

local function getClosestGarage()
    local coords = GetEntityCoords(PlayerPedId())
    local closest, distance
    for id, garage in pairs(Garages) do
        local dist = #(coords - garage.coords)
        if not distance or dist < distance then closest, distance = id, dist end
    end
    return closest, distance
end

local function openGarage()
    if uiOpen then return end
    local id, distance = getClosestGarage()
    if not id or distance > Config.OpenDistance then
        return notify('Je bent niet in de buurt van een garage.')
    end
    currentGarage = id
    TriggerServerEvent('thootje-garage:server:open', id)
end

RegisterCommand(Config.Command, openGarage, false)
RegisterKeyMapping(Config.Command, 'Open garage', 'keyboard', Config.Key)

RegisterNetEvent('thootje-garage:client:open', function(data)
    uiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', data = data })
end)

RegisterNetEvent('thootje-garage:client:update', function(data)
    SendNUIMessage({ action = 'update', data = data })
end)

RegisterNetEvent('thootje-garage:client:notify', notify)

RegisterNetEvent('thootje-garage:client:spawn', function(vehicle, spawn)
    local model = joaat(vehicle.model)
    if not IsModelInCdimage(model) or not IsModelAVehicle(model) then
        TriggerServerEvent('thootje-garage:server:spawnFailed', vehicle.plate)
        return notify('Dit voertuigmodel bestaat niet.')
    end

    local spawnCoords = vector3(spawn.x, spawn.y, spawn.z)
    if IsAnyVehicleNearPoint(spawnCoords.x, spawnCoords.y, spawnCoords.z, Config.SpawnClearRadius) then
        TriggerServerEvent('thootje-garage:server:spawnFailed', vehicle.plate)
        return notify('De uitrijplek is geblokkeerd.')
    end

    RequestModel(model)
    local timeout = GetGameTimer() + 10000
    while not HasModelLoaded(model) and GetGameTimer() < timeout do Wait(50) end
    if not HasModelLoaded(model) then
        TriggerServerEvent('thootje-garage:server:spawnFailed', vehicle.plate)
        return notify('Voertuigmodel kon niet worden geladen.')
    end

    local veh = CreateVehicle(model, spawn.x, spawn.y, spawn.z, spawn.w, true, false)
    if not DoesEntityExist(veh) then
        TriggerServerEvent('thootje-garage:server:spawnFailed', vehicle.plate)
        return notify('Voertuig kon niet worden aangemaakt.')
    end

    SetEntityAsMissionEntity(veh, true, true)
    SetVehicleNumberPlateText(veh, vehicle.plate)
    SetVehicleOnGroundProperly(veh)
    SetVehicleDirtLevel(veh, tonumber(vehicle.data.dirt) or 0.0)
    SetVehicleEngineHealth(veh, tonumber(vehicle.data.engine) or Config.VehicleDefaults.engine)
    SetVehicleBodyHealth(veh, tonumber(vehicle.data.body) or Config.VehicleDefaults.body)
    SetVehicleFuelLevel(veh, tonumber(vehicle.data.fuel) or Config.VehicleDefaults.fuel)

    if vehicle.data.props then
        local props = vehicle.data.props
        if props.color1 then SetVehicleColours(veh, props.color1, props.color2 or props.color1) end
        if props.pearlescentColor then SetVehicleExtraColours(veh, props.pearlescentColor, props.wheelColor or 0) end
        if props.wheelType then SetVehicleWheelType(veh, props.wheelType) end
        if props.windowTint then SetVehicleWindowTint(veh, props.windowTint) end
        if props.livery then SetVehicleLivery(veh, props.livery) end
        if props.mods then
            SetVehicleModKit(veh, 0)
            for modType, modIndex in pairs(props.mods) do
                local mt, mi = tonumber(modType), tonumber(modIndex)
                if mt and mi then SetVehicleMod(veh, mt, mi, false) end
            end
        end
    end

    SetModelAsNoLongerNeeded(model)
    TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
    spawnedVehicles[vehicle.plate] = veh
    TriggerServerEvent('thootje-garage:server:spawned', vehicle.plate, VehToNet(veh))
end)

RegisterNetEvent('thootje-garage:client:impoundResult', function(data)
    SendNUIMessage({ action = 'update', data = data })
end)

RegisterNUICallback('close', function(_, cb)
    uiOpen = false
    SetNuiFocus(false, false)
    cb({ ok = true })
end)

RegisterNUICallback('refresh', function(_, cb)
    if currentGarage then TriggerServerEvent('thootje-garage:server:refresh', currentGarage) end
    cb({ ok = true })
end)

RegisterNUICallback('takeOut', function(data, cb)
    TriggerServerEvent('thootje-garage:server:takeOut', tonumber(data.id), currentGarage)
    cb({ ok = true })
end)

RegisterNUICallback('store', function(_, cb)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 or GetPedInVehicleSeat(veh, -1) ~= ped then
        notify('Je moet als bestuurder in een voertuig zitten.')
        cb({ ok = false }); return
    end
    local id, distance = getClosestGarage()
    if not id or distance > Config.InteractDistance then
        notify('Je staat niet bij een garage.')
        cb({ ok = false }); return
    end
    local props = {
        fuel = GetVehicleFuelLevel(veh),
        engine = GetVehicleEngineHealth(veh),
        body = GetVehicleBodyHealth(veh),
        dirt = GetVehicleDirtLevel(veh),
        props = {
            color1 = select(1, GetVehicleColours(veh)),
            color2 = select(2, GetVehicleColours(veh)),
            pearlescentColor = select(1, GetVehicleExtraColours(veh)),
            wheelColor = select(2, GetVehicleExtraColours(veh)),
            wheelType = GetVehicleWheelType(veh),
            windowTint = GetVehicleWindowTint(veh),
            livery = GetVehicleLivery(veh),
            mods = {}
        }
    }
    for i = 0, 49 do
        props.props.mods[tostring(i)] = GetVehicleMod(veh, i)
    end
    TriggerServerEvent('thootje-garage:server:store', GetVehicleNumberPlateText(veh), id, props, VehToNet(veh))
    cb({ ok = true })
end)

RegisterNUICallback('impound', function(data, cb)
    TriggerServerEvent('thootje-garage:server:releaseImpound', tonumber(data.id), currentGarage)
    cb({ ok = true })
end)

RegisterNUICallback('rename', function(data, cb)
    TriggerServerEvent('thootje-garage:server:rename', tonumber(data.id), tostring(data.nickname or ''))
    cb({ ok = true })
end)

CreateThread(function()
    for id, garage in pairs(Garages) do
        if garage.blip and garage.type == 'public' and Config.Blips.garage.enabled then
            local blip = AddBlipForCoord(garage.coords.x, garage.coords.y, garage.coords.z)
            SetBlipSprite(blip, Config.Blips.garage.sprite)
            SetBlipColour(blip, Config.Blips.garage.color)
            SetBlipScale(blip, Config.Blips.garage.scale)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING'); AddTextComponentString(Config.Blips.garage.label); EndTextCommandSetBlipName(blip)
        elseif garage.blip and garage.type == 'impound' and Config.Blips.impound.enabled then
            local blip = AddBlipForCoord(garage.coords.x, garage.coords.y, garage.coords.z)
            SetBlipSprite(blip, Config.Blips.impound.sprite)
            SetBlipColour(blip, Config.Blips.impound.color)
            SetBlipScale(blip, Config.Blips.impound.scale)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING'); AddTextComponentString(Config.Blips.impound.label); EndTextCommandSetBlipName(blip)
        end
    end

    while true do
        local wait = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        for id, garage in pairs(Garages) do
            local dist = #(coords - garage.coords)
            if dist < 25.0 then
                wait = 0
                DrawMarker(1, garage.coords.x, garage.coords.y, garage.coords.z - 1.0, 0.0,0.0,0.0,0.0,0.0,0.0, 1.25,1.25,0.35, 49,205,184,120, false,true,2,false,nil,nil,false)
                if dist < Config.InteractDistance then
                    SetTextComponentFormat('STRING'); AddTextComponentString('Druk op ~INPUT_CONTEXT~ om garage te openen'); DisplayHelpTextFromStringLabel(0, false, true, -1)
                    if IsControlJustReleased(0, 38) then
                        currentGarage = id
                        TriggerServerEvent('thootje-garage:server:open', id)
                    end
                end
            end
        end
        Wait(wait)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then SetNuiFocus(false, false) end
end)
