local isOpen = false
local currentShop = nil
local nearbyShop = nil

local function notify(msg)
    TriggerEvent('thootje-core:client:notify', msg, 'info')
end

local function openShop(shopId)
    if isOpen then return end
    TriggerServerEvent('thootje-shops:server:openShop', shopId)
end

RegisterNetEvent('thootje-shops:client:openShop', function(shopId, data)
    currentShop = shopId
    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', shop = data })
end)

RegisterNetEvent('thootje-shops:client:notify', function(msg)
    notify(msg)
end)

RegisterNUICallback('close', function(_, cb)
    isOpen = false
    currentShop = nil
    SetNuiFocus(false, false)
    cb({ ok = true })
end)

RegisterNUICallback('buy', function(data, cb)
    if not currentShop then cb({ ok = false }); return end
    TriggerServerEvent('thootje-shops:server:buy', currentShop, data.item, tonumber(data.amount) or 1)
    cb({ ok = true })
end)

RegisterNUICallback('sell', function(data, cb)
    if not currentShop then cb({ ok = false }); return end
    TriggerServerEvent('thootje-shops:server:sell', currentShop, data.item, tonumber(data.amount) or 1)
    cb({ ok = true })
end)

RegisterCommand(Config.OpenCommand, function()
    if nearbyShop then openShop(nearbyShop) else notify('Er is geen winkel in de buurt.') end
end, false)

CreateThread(function()
    for id, shop in pairs(Config.Shops) do
        if Config.Blips.enabled and shop.blip then
            local blip = AddBlipForCoord(shop.coords.x, shop.coords.y, shop.coords.z)
            SetBlipSprite(blip, Config.Blips.sprite)
            SetBlipColour(blip, Config.Blips.color)
            SetBlipScale(blip, Config.Blips.scale)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString(shop.label)
            EndTextCommandSetBlipName(blip)
        end
    end
end)

CreateThread(function()
    while true do
        local wait = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        nearbyShop = nil

        for id, shop in pairs(Config.Shops) do
            local distance = #(coords - shop.coords)
            if distance < Config.DrawDistance then
                wait = 0
                DrawMarker(2, shop.coords.x, shop.coords.y, shop.coords.z + 0.15,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    0.25, 0.25, 0.25, 35, 190, 180, 180,
                    false, true, 2, false, nil, nil, false)
                if distance <= Config.InteractDistance then
                    nearbyShop = id
                    BeginTextCommandDisplayHelp('STRING')
                    AddTextComponentSubstringPlayerName(('Druk op ~INPUT_CONTEXT~ om %s te openen'):format(shop.label))
                    EndTextCommandDisplayHelp(0, false, true, -1)
                    if IsControlJustReleased(0, Config.InteractKey) then openShop(id) end
                end
            end
        end
        Wait(wait)
    end
end)

RegisterKeyMapping(Config.OpenCommand, 'Open dichtstbijzijnde winkel', 'keyboard', 'F7')
