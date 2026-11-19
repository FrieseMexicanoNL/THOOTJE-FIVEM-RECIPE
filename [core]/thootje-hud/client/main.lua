local hudOpen = false
local playerData = {}
local needs = { hunger = Config.DefaultNeeds.hunger, thirst = Config.DefaultNeeds.thirst }
local lastVehicleState = false

local function debugPrint(...)
    if Config.Debug then print('^3[thootje-hud]^7', ...) end
end

local function getCoreData()
    local ok, core = pcall(function()
        return exports[Config.Core.Resource]:GetCoreObject()
    end)
    if ok and core and core.Functions and core.Functions.GetPlayerData then
        local success, data = pcall(function() return core.Functions.GetPlayerData() end)
        if success and type(data) == 'table' then return data end
    end

    local ok2, data2 = pcall(function()
        return exports[Config.Core.Resource][Config.Core.GetPlayerDataExport]()
    end)
    if ok2 and type(data2) == 'table' then return data2 end
    return playerData
end

local function updatePlayerData(data)
    if type(data) == 'table' then
        playerData = data
        local meta = data.metadata or data.meta or {}
        if meta.hunger ~= nil then needs.hunger = tonumber(meta.hunger) or needs.hunger end
        if meta.thirst ~= nil then needs.thirst = tonumber(meta.thirst) or needs.thirst end
    end
end

RegisterNetEvent(Config.Core.PlayerLoadedEvent, function(data)
    updatePlayerData(data or getCoreData())
end)

RegisterNetEvent(Config.Core.PlayerDataEvent, function(data)
    updatePlayerData(data)
end)

RegisterNetEvent('thootje-hud:client:setNeeds', function(hunger, thirst)
    if hunger ~= nil then needs.hunger = math.max(0, math.min(100, tonumber(hunger) or 0)) end
    if thirst ~= nil then needs.thirst = math.max(0, math.min(100, tonumber(thirst) or 0)) end
end)

local function getMoney(kind)
    local money = playerData.money or {}
    if kind == 'cash' then
        return tonumber(money.cash or playerData.cash or 0) or 0
    end
    return tonumber(money.bank or playerData.bank or 0) or 0
end

local function getJob()
    local job = playerData.job or {}
    if type(job) ~= 'table' then return tostring(job) end
    return job.label or job.name or 'Werkloos'
end

local function sendHudData()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local streetHash, crossingHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local street = GetStreetNameFromHashKey(streetHash)
    local crossing = crossingHash ~= 0 and GetStreetNameFromHashKey(crossingHash) or ''
    local hour, minute = GetClockHours(), GetClockMinutes()
    local voiceMode = NetworkIsPlayerTalking(PlayerId()) and 'Praten' or 'Stil'
    local inVehicle = IsPedInAnyVehicle(ped, false)
    local vehicleData = nil

    if inVehicle then
        local veh = GetVehiclePedIsIn(ped, false)
        local speed = math.floor(GetEntitySpeed(veh) * 3.6 + 0.5)
        local fuel = 0
        if GetResourceState('LegacyFuel') == 'started' then
            fuel = exports['LegacyFuel']:GetFuel(veh)
        elseif GetResourceState('ox_fuel') == 'started' then
            fuel = exports.ox_fuel:getFuel(veh)
        else
            fuel = GetVehicleFuelLevel(veh)
        end
        vehicleData = {
            speed = speed,
            fuel = math.floor(fuel + 0.5),
            engine = GetVehicleEngineHealth(veh) / 10,
            seatbelt = LocalPlayer.state and LocalPlayer.state.seatbelt or false
        }
    end

    local stamina = 100 - GetPlayerSprintStaminaRemaining(PlayerId())
    local oxygen = 100
    if IsPedSwimmingUnderWater(ped) then
        oxygen = math.floor(GetPlayerUnderwaterTimeRemaining(PlayerId()) / 10 * 100)
    end

    SendNUIMessage({
        action = 'update',
        data = {
            health = math.max(0, GetEntityHealth(ped) - 100),
            armor = GetPedArmour(ped),
            hunger = needs.hunger,
            thirst = needs.thirst,
            stamina = math.floor(stamina),
            oxygen = math.max(0, math.min(100, oxygen)),
            voice = voiceMode,
            talking = NetworkIsPlayerTalking(PlayerId()),
            street = street ~= '' and street or 'Onbekende straat',
            crossing = crossing,
            heading = GetEntityHeading(ped),
            time = string.format('%02d:%02d', hour, minute),
            player = GetPlayerServerId(PlayerId()),
            job = getJob(),
            cash = getMoney('cash'),
            bank = getMoney('bank'),
            vehicle = vehicleData
        }
    })
end

RegisterCommand(Config.OpenCommand, function()
    hudOpen = not hudOpen
    SetNuiFocus(hudOpen, hudOpen)
    SendNUIMessage({ action = 'editor', open = hudOpen })
end, false)
RegisterKeyMapping(Config.OpenCommand, 'Open THOOTJE HUD instellingen', 'keyboard', Config.OpenKey)

RegisterNUICallback('close', function(_, cb)
    hudOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'editor', open = false })
    cb('ok')
end)

RegisterNUICallback('save', function(data, cb)
    if type(data) == 'table' then
        SetResourceKvp('thootje_hud_settings', json.encode(data))
        SendNUIMessage({ action = 'settings', settings = data })
    end
    cb('ok')
end)

RegisterNUICallback('reset', function(_, cb)
    DeleteResourceKvp('thootje_hud_settings')
    SendNUIMessage({ action = 'reset' })
    cb('ok')
end)

CreateThread(function()
    Wait(1500)
    updatePlayerData(getCoreData())
    local saved = GetResourceKvpString('thootje_hud_settings')
    if saved then
        local ok, decoded = pcall(json.decode, saved)
        if ok and type(decoded) == 'table' then
            SendNUIMessage({ action = 'settings', settings = decoded })
        end
    end
    while true do
        sendHudData()
        Wait(500)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then SetNuiFocus(false, false) end
end)
