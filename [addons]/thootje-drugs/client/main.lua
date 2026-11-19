local busy, nearbyNPC = false, nil
local function notify(message, kind)
    lib.notify({ title = 'THOOTJE DRUGS', description = message, type = kind or 'inform' })
end

RegisterNetEvent('thootje-drugs:client:notify', function(message, kind)
    notify(message, kind)
end)

local function help(text)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

local function doProgress(label, duration)
    if busy then return false end
    busy = true
    local ok = lib.progressCircle({
        duration = duration,
        label = label,
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true }
    })
    busy = false
    return ok
end

local function chooseDrug(stage)
    local options = {}
    for key, drug in pairs(Config.Drugs) do
        local enabled = true
        if stage == 'farm' and (drug.secondary or not drug.farm or drug.farm.max <= 0) then enabled = false end
        if enabled then options[#options+1] = { label = drug.label, value = key } end
    end
    table.sort(options, function(a,b) return a.label < b.label end)
    local input = lib.inputDialog('Kies product', {
        { type = 'select', label = 'Product', options = options, required = true }
    })
    return input and input[1]
end

local function interactZone(zone)
    if busy then return end
    if zone.type == 'sell' then
        if doProgress('Contact leggen met afnemer...', Config.Progress.Sell) then
            TriggerServerEvent('thootje-drugs:server:sellAtPoint', zone.id)
        end
        return
    end
    local drugKey = zone.drug or chooseDrug(zone.type)
    if not drugKey then return end
    local labels = { farm='Grondstoffen verzamelen...', dry='Product drogen...', process='Product verwerken...', package='Verpakkingen klaarmaken...' }
    if doProgress(labels[zone.type] or 'Bezig...', Config.Progress[zone.type] or 4000) then
        TriggerServerEvent('thootje-drugs:server:stage', zone.id, zone.type, drugKey)
    end
end

CreateThread(function()
    while true do
        local wait = 900
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        for _, zone in ipairs(Config.Zones) do
            local dist = #(coords - zone.coords)
            if dist < Config.DrawDistance then
                wait = 0
                DrawMarker(Config.MarkerType, zone.coords.x, zone.coords.y, zone.coords.z - 0.85,
                    0.0,0.0,0.0, 0.0,0.0,0.0, Config.MarkerScale.x,Config.MarkerScale.y,Config.MarkerScale.z,
                    20, 190, 170, 170, false, true, 2, false, nil, nil, false)
                if dist <= (zone.radius or Config.InteractDistance) then
                    help(('Druk op ~INPUT_CONTEXT~ om ~b~%s~s~'):format(zone.label))
                    if IsControlJustReleased(0, Config.InteractKey) then interactZone(zone) end
                end
            end
        end
        Wait(wait)
    end
end)

local function findSellNPC()
    local playerPed = PlayerPedId()
    local pcoords = GetEntityCoords(playerPed)
    local handle, ped = FindFirstPed()
    local success
    repeat
        if DoesEntityExist(ped) and not IsPedAPlayer(ped) and not IsPedDeadOrDying(ped, true) then
            local dist = #(GetEntityCoords(ped) - pcoords)
            if dist <= Config.Selling.SearchRadius and not IsPedInAnyVehicle(ped, false) then
                EndFindPed(handle)
                return ped
            end
        end
        success, ped = FindNextPed(handle)
    until not success
    EndFindPed(handle)
    return nil
end

RegisterCommand('drugsell', function()
    if not Config.Selling.Enabled then return end
    local npc = findSellNPC()
    if not npc then return notify('Er is niemand in de buurt die je kunt benaderen.', 'error') end
    TaskTurnPedToFaceEntity(npc, PlayerPedId(), 1000)
    TaskTurnPedToFaceEntity(PlayerPedId(), npc, 1000)
    Wait(350)
    if not NetworkGetEntityIsNetworked(npc) then
        NetworkRegisterEntityAsNetworked(npc)
        Wait(100)
    end
    local netId = NetworkGetNetworkIdFromEntity(npc)
    if not netId or netId == 0 then return notify('Deze persoon kan niet worden benaderd.', 'error') end
    TriggerServerEvent('thootje-drugs:server:sellToNPC', netId)
end, false)

RegisterKeyMapping('drugsell', 'THOOTJE DRUGS: benader NPC voor verkoop', 'keyboard', 'G')

RegisterCommand('druginfo', function()
    local lines = {}
    for key, drug in pairs(Config.Drugs) do
        lines[#lines+1] = ('• %s — item: %s'):format(drug.label, drug.package)
    end
    table.sort(lines)
    lib.alertDialog({ header = 'THOOTJE DRUGS — Producten', content = table.concat(lines, '\n'), centered = true, cancel = true })
end, false)

RegisterNetEvent('thootje-drugs:client:policeCount', function(count)
    notify(('Actieve politie: %s'):format(count), 'inform')
end)

if Config.Blips.Enabled then
    CreateThread(function()
        for _, zone in ipairs(Config.Zones) do
            local blip = AddBlipForCoord(zone.coords.x, zone.coords.y, zone.coords.z)
            SetBlipSprite(blip, Config.Blips.Sprite)
            SetBlipScale(blip, Config.Blips.Scale)
            SetBlipColour(blip, Config.Blips.Colour)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString(zone.label)
            EndTextCommandSetBlipName(blip)
        end
    end)
end
