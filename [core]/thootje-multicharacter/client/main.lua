local cam = nil
local previewPed = nil
local isOpen = false
local spawnOptions = {}

local function cleanupPreview()
    if cam then RenderScriptCams(false, true, 500, true, true) DestroyCam(cam, false) cam = nil end
    if previewPed and DoesEntityExist(previewPed) then DeleteEntity(previewPed) previewPed = nil end
end

local function createPreview()
    local c = Config.Preview.coords
    local model = joaat('mp_m_freemode_01')
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end
    previewPed = CreatePed(4, model, c.x, c.y, c.z, c.w, false, true)
    SetEntityInvincible(previewPed, true)
    FreezeEntityPosition(previewPed, true)
    SetBlockingOfNonTemporaryEvents(previewPed, true)
    SetEntityAlpha(previewPed, 255, false)
    TaskStartScenarioInPlace(previewPed, 'WORLD_HUMAN_STAND_IMPATIENT', 0, true)
    SetModelAsNoLongerNeeded(model)

    local cc = Config.Preview.camera
    cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(cam, cc.x, cc.y, cc.z)
    PointCamAtEntity(cam, previewPed, 0.0, 0.0, 0.65, true)
    SetCamFov(cam, Config.Preview.fov or 38.0)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 700, true, true)
end

RegisterNetEvent('thootje-multicharacter:client:open', function(characters, maxCharacters, labels)
    isOpen = true
    DoScreenFadeOut(0)
    Wait(300)
    local p = Config.Preview.coords
    SetEntityCoords(PlayerPedId(), p.x, p.y, p.z, false, false, false, false)
    SetEntityHeading(PlayerPedId(), p.w)
    FreezeEntityPosition(PlayerPedId(), true)
    createPreview()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open', characters = characters or {},
        maxCharacters = maxCharacters, labels = labels or {}
    })
    DoScreenFadeIn(700)
end)

RegisterNetEvent('thootje-multicharacter:client:updateCharacters', function(characters)
    SendNUIMessage({ action = 'characters', characters = characters or {} })
end)

RegisterNetEvent('thootje-multicharacter:client:notify', function(message)
    SendNUIMessage({ action = 'notify', message = message })
end)

RegisterNetEvent('thootje-multicharacter:client:spawnSelector', function(spawns, character)
    spawnOptions = spawns or {}
    SendNUIMessage({ action = 'spawn', spawns = spawnOptions, character = character })
end)

RegisterNetEvent('thootje-multicharacter:client:finishSpawn', function(coords)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    cleanupPreview()
    local ped = PlayerPedId()
    DoScreenFadeOut(500)
    Wait(600)
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityHeading(ped, coords.w or 0.0)
    FreezeEntityPosition(ped, false)
    SetEntityVisible(ped, true, false)
    SetPlayerControl(PlayerId(), true, 0)
    DoScreenFadeIn(1000)
    isOpen = false
    TriggerEvent('thootje-multicharacter:client:spawned')
end)

RegisterNUICallback('create', function(data, cb)
    TriggerServerEvent('thootje-multicharacter:server:createCharacter', data)
    cb({ ok = true })
end)

RegisterNUICallback('select', function(data, cb)
    TriggerServerEvent('thootje-multicharacter:server:selectCharacter', data.id)
    cb({ ok = true })
end)

RegisterNUICallback('delete', function(data, cb)
    TriggerServerEvent('thootje-multicharacter:server:deleteCharacter', data.id)
    cb({ ok = true })
end)

RegisterNUICallback('spawn', function(data, cb)
    TriggerServerEvent('thootje-multicharacter:server:finishSpawn', data.index)
    cb({ ok = true })
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        SetNuiFocus(false, false)
        cleanupPreview()
        FreezeEntityPosition(PlayerPedId(), false)
    end
end)
