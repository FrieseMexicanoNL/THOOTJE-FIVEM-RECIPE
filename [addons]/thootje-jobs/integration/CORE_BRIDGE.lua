-- Optionele koppeling voor THOOTJE-CORE:
-- Luister server-side naar wijzigingen en schrijf het jobobject in je actieve playerdata.
AddEventHandler('thootje-jobs:server:jobUpdated', function(source, jobData)
    -- Voorbeeld:
    -- local Player = exports['thootje-core']:GetPlayer(source)
    -- if Player then
    --     Player.job = jobData
    --     exports['thootje-core']:SavePlayer(source)
    -- end
    --
    -- Vervang dit voorbeeld met de echte API van jouw THOOTJE-CORE.
end)

-- Andere resources kunnen de job lezen:
-- local job = exports['thootje-jobs']:GetJob(source)
-- if job and job.name == 'police' and job.onduty then ... end
