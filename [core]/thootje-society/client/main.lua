local uiOpen = false
local function notify(msg)
    TriggerEvent('thootje-core:client:notify', msg, 'info')
end

local function openSociety()
    if uiOpen then return end
    TriggerServerEvent('thootje-society:server:open')
end

RegisterCommand(Config.Command, openSociety, false)
RegisterKeyMapping(Config.Command, 'Open bedrijfsbeheer', 'keyboard', Config.BossKey)

RegisterNetEvent('thootje-society:client:open', function(data)
    uiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', data = data })
end)

RegisterNetEvent('thootje-society:client:update', function(data)
    SendNUIMessage({ action = 'update', data = data })
end)

RegisterNetEvent('thootje-society:client:notify', notify)

RegisterNUICallback('close', function(_, cb)
    uiOpen = false
    SetNuiFocus(false, false)
    cb({ ok = true })
end)

RegisterNUICallback('refresh', function(_, cb)
    TriggerServerEvent('thootje-society:server:refresh')
    cb({ ok = true })
end)

RegisterNUICallback('deposit', function(data, cb)
    TriggerServerEvent('thootje-society:server:deposit', tonumber(data.amount), tostring(data.description or 'Storting'))
    cb({ ok = true })
end)

RegisterNUICallback('withdraw', function(data, cb)
    TriggerServerEvent('thootje-society:server:withdraw', tonumber(data.amount), tostring(data.description or 'Opname'))
    cb({ ok = true })
end)

RegisterNUICallback('transfer', function(data, cb)
    TriggerServerEvent('thootje-society:server:transfer', tostring(data.target or ''), tonumber(data.amount), tostring(data.description or 'Overboeking'))
    cb({ ok = true })
end)

RegisterNUICallback('hire', function(data, cb)
    TriggerServerEvent('thootje-society:server:hire', tonumber(data.playerId), tonumber(data.grade) or 0)
    cb({ ok = true })
end)

RegisterNUICallback('setGrade', function(data, cb)
    TriggerServerEvent('thootje-society:server:setGrade', tonumber(data.employeeId), tonumber(data.grade))
    cb({ ok = true })
end)

RegisterNUICallback('fire', function(data, cb)
    TriggerServerEvent('thootje-society:server:fire', tonumber(data.employeeId))
    cb({ ok = true })
end)
