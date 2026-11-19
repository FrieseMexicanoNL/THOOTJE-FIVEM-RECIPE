-- Voorbeeldserver-handler voor thootje-politiejob.
-- Voeg dit toe aan de serverzijde van de politiejob als die nog geen drugs-alert-event heeft.
RegisterNetEvent('thootje-politiejob:server:drugAlert', function(payload)
    if type(payload) ~= 'table' or type(payload.coords) ~= 'table' then return end
    local coords = vector3(tonumber(payload.coords.x) or 0.0, tonumber(payload.coords.y) or 0.0, tonumber(payload.coords.z) or 0.0)
    for _, player in ipairs(GetPlayers()) do
        local src = tonumber(player)
        -- Vervang deze state-check eventueel door jouw eigen THOOTJE-JOBS bridge.
        local job = Player(src).state.thootjeJob
        if type(job) == 'table' and (job.name == 'police' or job.job == 'police') and (job.duty == true or job.onduty == true) then
            TriggerClientEvent('thootje-politiejob:client:drugAlert', src, {
                code = payload.code or '10-31',
                title = payload.title or 'Mogelijke drugsdeal',
                description = payload.description or 'Melding van een mogelijke drugsdeal',
                coords = coords,
                duration = payload.duration or 90
            })
        end
    end
end)
