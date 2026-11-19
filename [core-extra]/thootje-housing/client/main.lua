local menuOpen = false
local blips = {}

local function notify(message, kind)
    TriggerEvent(Config.NotifyEvent, kind or 'info', message)
end

local function openMenu(properties)
    menuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', properties = properties })
end

RegisterNetEvent('thootje-housing:client:open', function(properties)
    openMenu(properties)
end)

RegisterNetEvent('thootje-housing:client:teleportInside', function(coords)
    DoScreenFadeOut(300)
    Wait(350)
    SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityHeading(PlayerPedId(), coords.w or 0.0)
    Wait(250)
    DoScreenFadeIn(300)
end)

RegisterNetEvent('thootje-housing:client:teleportOutside', function(coords)
    DoScreenFadeOut(300)
    Wait(350)
    SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityHeading(PlayerPedId(), coords.w or 0.0)
    Wait(250)
    DoScreenFadeIn(300)
end)

RegisterNUICallback('close', function(_, cb)
    menuOpen = false
    SetNuiFocus(false, false)
    cb({ ok = true })
end)

RegisterNUICallback('purchase', function(data, cb)
    TriggerServerEvent('thootje-housing:server:purchase', data.id, data.mode)
    cb({ ok = true })
end)

RegisterNUICallback('enter', function(data, cb)
    TriggerServerEvent('thootje-housing:server:enter', data.id)
    menuOpen = false
    SetNuiFocus(false, false)
    cb({ ok = true })
end)

RegisterNUICallback('shareKey', function(data, cb)
    TriggerServerEvent('thootje-housing:server:shareKey', data.id, data.target)
    cb({ ok = true })
end)

RegisterNUICallback('revokeKey', function(data, cb)
    TriggerServerEvent('thootje-housing:server:revokeKey', data.id, data.identifier)
    cb({ ok = true })
end)

RegisterCommand('huis', function()
    TriggerServerEvent('thootje-housing:server:requestProperties')
end)

RegisterKeyMapping('huis', 'Open woningmenu', 'keyboard', 'F7')

CreateThread(function()
    for _, property in ipairs(Config.Properties) do
        if Config.PropertyBlip.enabled then
            local c = property.exterior
            local blip = AddBlipForCoord(c.x, c.y, c.z)
            SetBlipSprite(blip, Config.PropertyBlip.sprite)
            SetBlipColour(blip, Config.PropertyBlip.color)
            SetBlipScale(blip, Config.PropertyBlip.scale)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString(property.label or Config.PropertyBlip.label)
            EndTextCommandSetBlipName(blip)
            blips[#blips + 1] = blip
        end
    end
end)

CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        for _, property in ipairs(Config.Properties) do
            local c = property.exterior
            local dist = #(coords - vector3(c.x, c.y, c.z))
            if dist < Config.DrawDistance then
                sleep = 0
                DrawMarker(2, c.x, c.y, c.z + 0.25, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.25, 0.25, 0.25, 35, 190, 170, 180, false, true, 2, false, nil, nil, false)
                if dist < Config.InteractDistance then
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName('Druk op ~INPUT_CONTEXT~ om woningen te bekijken')
                    EndTextCommandDisplayHelp(0, false, true, -1)
                    if IsControlJustReleased(0, 38) then
                        TriggerServerEvent('thootje-housing:server:requestProperties')
                    end
                end
            end
        end

        local interior = Config.Interiors.apartment
        local house = Config.Interiors.house
        for _, point in ipairs({ interior.exit, house.exit }) do
            local d = #(coords - vector3(point.x, point.y, point.z))
            if d < 2.0 then
                sleep = 0
                BeginTextCommandDisplayHelp('STRING')
                AddTextComponentSubstringPlayerName('Druk op ~INPUT_CONTEXT~ om de woning te verlaten')
                EndTextCommandDisplayHelp(0, false, true, -1)
                if IsControlJustReleased(0, 38) then TriggerServerEvent('thootje-housing:server:exit') end
            end
        end
        Wait(sleep)
    end
end)
