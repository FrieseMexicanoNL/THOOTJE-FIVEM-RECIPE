local Core = exports['thootje-core']:GetCoreObject()
local sessions = {}

local function log(...)
    if Config.Debug then print('^3[THOOTJE-MULTICHARACTER]^7', ...) end
end

local function getLicense(src)
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if id:sub(1, 8) == 'license:' then return id end
    end
    return nil
end

local function cleanName(value)
    if type(value) ~= 'string' then return nil end
    value = value:gsub('[^%aÀ-ÿ%s%-]', ''):gsub('^%s*(.-)%s*$', '%1')
    if #value < 2 or #value > 32 then return nil end
    return value
end

local function getCharacters(src)
    local owner = getLicense(src)
    if not owner then return {} end
    return MySQL.query.await(
        'SELECT id, slot, firstname, lastname, dateofbirth, gender, nationality FROM thootje_characters WHERE owner = ? ORDER BY slot ASC',
        { owner }
    ) or {}
end

local function showSelection(src)
    local owner = getLicense(src)
    if not owner then DropPlayer(src, 'Thootje: license identifier ontbreekt.') return end
    sessions[src] = { owner = owner, selected = false }
    TriggerClientEvent('thootje-multicharacter:client:open', src, getCharacters(src), Config.MaxCharacters, Config.Text)
end

AddEventHandler('playerJoining', function()
    local src = source
    CreateThread(function()
        Wait(500)
        if GetPlayerName(src) then showSelection(src) end
    end)
end)

RegisterNetEvent('thootje-multicharacter:server:requestCharacters', function()
    local src = source
    local s = sessions[src]
    if not s then showSelection(src) return end
    TriggerClientEvent('thootje-multicharacter:client:updateCharacters', src, getCharacters(src))
end)

RegisterNetEvent('thootje-multicharacter:server:createCharacter', function(data)
    local src = source
    local s = sessions[src]
    if not s or s.selected then return end
    if type(data) ~= 'table' then return end

    local firstname = cleanName(data.firstname)
    local lastname = cleanName(data.lastname)
    local dob = tostring(data.dateofbirth or '')
    local gender = data.gender == 'vrouw' and 'vrouw' or 'man'
    local nationality = cleanName(data.nationality or 'Nederlands') or 'Nederlands'

    if not firstname or not lastname or not dob:match('^%d%d%-%d%d%-%d%d%d%d$') then
        TriggerClientEvent('thootje-multicharacter:client:notify', src, 'Vul geldige persoonsgegevens in.')
        return
    end

    local count = MySQL.scalar.await('SELECT COUNT(*) FROM thootje_characters WHERE owner = ?', { s.owner }) or 0
    if count >= Config.MaxCharacters then
        TriggerClientEvent('thootje-multicharacter:client:notify', src, 'Je hebt het maximale aantal personages bereikt.')
        return
    end

    local slot = MySQL.scalar.await(
        'SELECT MIN(t.slot + 1) FROM thootje_characters t LEFT JOIN thootje_characters n ON n.owner = t.owner AND n.slot = t.slot + 1 WHERE t.owner = ? AND n.id IS NULL',
        { s.owner }
    )
    slot = tonumber(slot) or 1
    if slot < 1 or slot > Config.MaxCharacters then slot = count + 1 end

    local id = MySQL.insert.await([[
        INSERT INTO thootje_characters (owner, slot, firstname, lastname, dateofbirth, gender, nationality)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], { s.owner, slot, firstname, lastname, dob, gender, nationality })

    if not id then
        TriggerClientEvent('thootje-multicharacter:client:notify', src, 'Personage aanmaken is mislukt.')
        return
    end

    log('Character aangemaakt', id, 'voor', src)
    TriggerClientEvent('thootje-multicharacter:client:updateCharacters', src, getCharacters(src))
end)

RegisterNetEvent('thootje-multicharacter:server:selectCharacter', function(characterId)
    local src = source
    local s = sessions[src]
    characterId = tonumber(characterId)
    if not s or s.selected or not characterId then return end

    local character = MySQL.single.await(
        'SELECT * FROM thootje_characters WHERE id = ? AND owner = ?',
        { characterId, s.owner }
    )
    if not character then return end

    s.selected = true
    local charIdentifier = ('%s:char:%s'):format(s.owner, character.id)
    local fullName = character.firstname .. ' ' .. character.lastname

    local ok = exports['thootje-core']:LoadPlayer(src, charIdentifier, fullName)
    if not ok then
        s.selected = false
        TriggerClientEvent('thootje-multicharacter:client:notify', src, 'Core kon het personage niet laden. Controleer de core-integratie.')
        return
    end

    TriggerClientEvent('thootje-multicharacter:client:spawnSelector', src, Config.Spawns, character)
    TriggerEvent('thootje-multicharacter:server:characterSelected', src, character)
end)

RegisterNetEvent('thootje-multicharacter:server:deleteCharacter', function(characterId)
    local src = source
    local s = sessions[src]
    if not Config.DeleteCharacters or not s or s.selected then return end
    characterId = tonumber(characterId)
    if not characterId then return end
    MySQL.update.await('DELETE FROM thootje_characters WHERE id = ? AND owner = ?', { characterId, s.owner })
    TriggerClientEvent('thootje-multicharacter:client:updateCharacters', src, getCharacters(src))
end)

RegisterNetEvent('thootje-multicharacter:server:finishSpawn', function(spawnIndex)
    local src = source
    local s = sessions[src]
    if not s or not s.selected then return end
    local spawn = Config.Spawns[tonumber(spawnIndex) or 0]
    if not spawn then return end
    TriggerClientEvent('thootje-multicharacter:client:finishSpawn', src, spawn.coords)
end)

AddEventHandler('playerDropped', function()
    sessions[source] = nil
end)
