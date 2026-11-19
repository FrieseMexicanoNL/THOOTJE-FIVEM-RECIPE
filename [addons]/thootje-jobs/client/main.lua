local menuOpen = false
local currentJob = nil

local function notify(msg, kind)
    SendNUIMessage({ action = 'toast', message = msg, kind = kind })
end

local function openMenu()
    if menuOpen then return end
    menuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'show' })
    TriggerServerEvent('thootje-jobs:server:requestData')
end

local function closeMenu()
    menuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'hide' })
end

RegisterCommand(Config.Commands.JobCenter, openMenu, false)
RegisterKeyMapping(Config.Commands.JobCenter, 'Open THOOTJE vacaturecentrum', 'keyboard', Config.Keybind)

RegisterNetEvent('thootje-jobs:client:openData', function(data)
    SendNUIMessage({ action = 'data', payload = data })
end)

RegisterNetEvent('thootje-jobs:client:setJob', function(data)
    currentJob = data
    LocalPlayer.state:set('thootjeJob', data, true)
    SendNUIMessage({ action = 'myjob', job = data })
end)

RegisterNetEvent('thootje-jobs:client:notify', function(msg, kind) notify(msg, kind) end)
RegisterNetEvent('thootje-jobs:client:jobChanged', function() if menuOpen then TriggerServerEvent('thootje-jobs:server:requestData') end end)

RegisterNUICallback('close', function(_, cb) closeMenu(); cb('ok') end)
RegisterNUICallback('apply', function(data, cb)
    TriggerServerEvent('thootje-jobs:server:applyJob', data.job)
    cb('ok')
end)
RegisterNUICallback('duty', function(_, cb)
    TriggerServerEvent('thootje-jobs:server:toggleDuty')
    cb('ok')
end)

CreateThread(function()
    while true do
        local wait = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        for _, pos in ipairs(Config.JobCenter.Locations) do
            local dist = #(coords - pos)
            if dist < Config.JobCenter.DrawDistance then
                wait = 0
                if Config.JobCenter.UseMarkers then
                    DrawMarker(2, pos.x, pos.y, pos.z + 0.15, 0,0,0,0,0,0,0.24,0.24,0.15,57,223,198,180,false,true,2,false,nil,nil,false)
                end
                if dist < Config.JobCenter.InteractDistance then
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName('Druk op ~INPUT_CONTEXT~ om het vacaturecentrum te openen')
                    EndTextCommandDisplayHelp(0, false, true, -1)
                    if IsControlJustReleased(0, 38) then openMenu() end
                end
            end
        end
        Wait(wait)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then SetNuiFocus(false, false) end
end)
