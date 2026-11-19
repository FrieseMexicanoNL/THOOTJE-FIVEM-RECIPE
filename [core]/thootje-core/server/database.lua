Thootje = Thootje or {}
Thootje.Players = Thootje.Players or {}

local function decode(value, fallback)
    if type(value) == 'table' then return value end
    if not value or value == '' then return fallback end
    local ok, result = pcall(json.decode, value)
    return ok and result or fallback
end

function Thootje.GetIdentifier(src)
    for _, identifier in ipairs(GetPlayerIdentifiers(src)) do
        if identifier:sub(1, 8) == 'license:' then return identifier end
    end
    return GetPlayerIdentifiers(src)[1]
end

function Thootje.LoadPlayer(src)
    local identifier = Thootje.GetIdentifier(src)
    if not identifier then
        DropPlayer(src, 'Thootje Core: geen geldig Rockstar/FiveM identifier gevonden.')
        return
    end

    local row = MySQL.single.await('SELECT * FROM thootje_players WHERE identifier = ?', { identifier })
    if not row then
        local accounts = Config.StartingMoney
        local job = Config.DefaultJob
        MySQL.insert.await([[
            INSERT INTO thootje_players
            (identifier, name, accounts, job, inventory, group_name)
            VALUES (?, ?, ?, ?, ?, ?)
        ]], {
            identifier, GetPlayerName(src) or 'Onbekend',
            json.encode(accounts), json.encode(job), json.encode({}), 'user'
        })
        row = MySQL.single.await('SELECT * FROM thootje_players WHERE identifier = ?', { identifier })
    end

    local player = {
        source = src,
        identifier = identifier,
        name = GetPlayerName(src) or row.name,
        accounts = decode(row.accounts, Config.StartingMoney),
        job = decode(row.job, Config.DefaultJob),
        inventory = decode(row.inventory, {}),
        group = row.group_name or 'user',
        loaded = true
    }
    Thootje.Players[src] = player
    TriggerClientEvent('thootje:client:playerLoaded', src, Thootje.GetPlayerData(src))
    TriggerEvent('thootje:server:playerLoaded', src, player)
    Thootje.Debug('Player geladen:', player.name, identifier)
end

function Thootje.SavePlayer(src)
    local player = Thootje.Players[src]
    if not player then return false end

    MySQL.update.await([[
        UPDATE thootje_players
        SET name = ?, accounts = ?, job = ?, inventory = ?, group_name = ?
        WHERE identifier = ?
    ]], {
        GetPlayerName(src) or player.name,
        json.encode(player.accounts), json.encode(player.job),
        json.encode(player.inventory), player.group, player.identifier
    })
    return true
end

function Thootje.GetPlayerData(src)
    local p = Thootje.Players[src]
    if not p then return nil end
    return {
        source = p.source, identifier = p.identifier, name = p.name,
        accounts = p.accounts, job = p.job, inventory = p.inventory, group = p.group
    }
end
