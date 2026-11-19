local Properties = {}
local ActiveHomes = {}

local function notify(src, message, kind)
    TriggerClientEvent(Config.NotifyEvent, src, kind or 'info', message)
end

local function getProperty(id)
    for _, property in ipairs(Config.Properties) do
        if property.id == id then return property end
    end
end

local function getOwner(propertyId)
    return MySQL.single.await('SELECT * FROM thootje_housing_ownership WHERE property_id = ?', { propertyId })
end

local function hasAccess(src, propertyId)
    local identifier = TH.GetIdentifier(src)
    local owner = getOwner(propertyId)
    if not owner then return false end
    if owner.owner_identifier == identifier then return true end
    local key = MySQL.single.await('SELECT id FROM thootje_housing_keys WHERE property_id = ? AND holder_identifier = ?', { propertyId, identifier })
    return key ~= nil
end

local function propertyData(property)
    local owner = getOwner(property.id)
    local row = {
        id = property.id, label = property.label, address = property.address,
        type = property.type, price = property.price, rent = property.rent,
        forSale = property.forSale, forRent = property.forRent,
        status = 'Beschikbaar', owned = false, isOwner = false
    }
    if owner then
        row.owned = true
        row.status = owner.rent_until and 'Verhuurd' or 'Verkocht'
        row.isOwner = owner.owner_identifier == 'unknown'
    end
    return row
end

local function sendProperties(src)
    local identifier = TH.GetIdentifier(src)
    local result = {}
    for _, property in ipairs(Config.Properties) do
        local row = propertyData(property)
        local owner = getOwner(property.id)
        row.isOwner = owner and owner.owner_identifier == identifier or false
        row.hasKey = owner and hasAccess(src, property.id) or false
        result[#result + 1] = row
    end
    TriggerClientEvent('thootje-housing:client:open', src, result)
end

RegisterNetEvent('thootje-housing:server:requestProperties', function()
    sendProperties(source)
end)

RegisterNetEvent('thootje-housing:server:purchase', function(propertyId, mode)
    local src = source
    local property = getProperty(propertyId)
    if not property then return notify(src, Config.Text.not_found, 'error') end
    local existing = getOwner(propertyId)
    if existing then return notify(src, Config.Text.already_owned, 'error') end

    local amount
    local rentUntil
    if mode == 'rent' and Config.RentEnabled and property.forRent then
        amount = tonumber(property.rent)
        rentUntil = os.time() + (Config.DefaultRentDays * 86400)
    elseif mode == 'buy' and Config.BuyEnabled and property.forSale then
        amount = tonumber(property.price)
    else
        return
    end
    if not amount or amount <= 0 then return end
    if not TH.RemoveMoney(src, amount, Config.PaymentAccount, 'Woning ' .. mode) then
        return notify(src, Config.Text.no_money, 'error')
    end

    local identifier = TH.GetIdentifier(src)
    MySQL.insert.await([[
        INSERT INTO thootje_housing_ownership
        (property_id, owner_identifier, owner_name, purchase_type, rent_until)
        VALUES (?, ?, ?, ?, ?)
    ]], { propertyId, identifier, TH.GetPlayerNameSafe(src), mode, rentUntil })
    notify(src, mode == 'rent' and Config.Text.rented or Config.Text.bought, 'success')
    sendProperties(src)
end)

RegisterNetEvent('thootje-housing:server:enter', function(propertyId)
    local src = source
    local property = getProperty(propertyId)
    if not property then return notify(src, Config.Text.not_found, 'error') end
    if not hasAccess(src, propertyId) then return notify(src, Config.Text.no_access, 'error') end
    local ped = GetPlayerPed(src)
    if ped and ped ~= 0 then
        local coords = GetEntityCoords(ped)
        local exterior = property.exterior
        if #(coords - vector3(exterior.x, exterior.y, exterior.z)) > 5.0 then
            return notify(src, 'Je staat niet bij de ingang van deze woning.', 'error')
        end
    end

    local interior = Config.Interiors[property.type]
    if not interior then return end
    local bucket = 5000 + math.abs(joaat(propertyId)) % 20000
    SetPlayerRoutingBucket(src, bucket)
    ActiveHomes[src] = propertyId
    TriggerClientEvent('thootje-housing:client:teleportInside', src, interior.entry)
    notify(src, Config.Text.entered, 'success')
end)

local function exitHome(src)
    local propertyId = ActiveHomes[src]
    if not propertyId then return end
    local property = getProperty(propertyId)
    if not property then return end
    SetPlayerRoutingBucket(src, 0)
    ActiveHomes[src] = nil
    TriggerClientEvent('thootje-housing:client:teleportOutside', src, property.exterior)
    notify(src, Config.Text.exited, 'success')
end

RegisterNetEvent('thootje-housing:server:exit', function()
    exitHome(source)
end)

local function shareKey(src, propertyId, targetId)
    targetId = tonumber(targetId)
    if not targetId or not GetPlayerName(targetId) then return end
    local owner = getOwner(propertyId)
    if not owner or owner.owner_identifier ~= TH.GetIdentifier(src) then
        return notify(src, Config.Text.not_owner, 'error')
    end
    local count = MySQL.scalar.await('SELECT COUNT(*) FROM thootje_housing_keys WHERE property_id = ?', { propertyId }) or 0
    if count >= Config.MaxKeysPerProperty then return notify(src, 'Je hebt het maximale aantal gedeelde sleutels bereikt.', 'error') end

    local targetIdentifier = TH.GetIdentifier(targetId)
    if targetIdentifier == owner.owner_identifier then return end
    MySQL.insert.await([[
        INSERT IGNORE INTO thootje_housing_keys (property_id, owner_identifier, holder_identifier, holder_name)
        VALUES (?, ?, ?, ?)
    ]], { propertyId, owner.owner_identifier, targetIdentifier, TH.GetPlayerNameSafe(targetId) })
    notify(src, Config.Text.keys_sent, 'success')
    notify(targetId, 'Je hebt een huissleutel ontvangen.', 'success')
end

RegisterNetEvent('thootje-housing:server:shareKey', function(propertyId, targetId)
    shareKey(source, propertyId, targetId)
end)

RegisterNetEvent('thootje-housing:server:revokeKey', function(propertyId, targetIdentifier)
    local src = source
    local owner = getOwner(propertyId)
    if not owner or owner.owner_identifier ~= TH.GetIdentifier(src) then
        return notify(src, Config.Text.not_owner, 'error')
    end
    MySQL.update.await('DELETE FROM thootje_housing_keys WHERE property_id = ? AND holder_identifier = ?', { propertyId, targetIdentifier })
    notify(src, Config.Text.keys_removed, 'success')
end)

lib = nil -- resource is standalone; no ox_lib dependency

RegisterCommand(Config.OpenCommand, function(src)
    if src == 0 then return end
    sendProperties(src)
end)

RegisterCommand(Config.ExitCommand, function(src)
    if src > 0 then exitHome(src) end
end)

RegisterCommand(Config.KeyCommand, function(src, args)
    if src == 0 then return end
    local propertyId = args[1]
    local targetId = tonumber(args[2])
    if propertyId and targetId then
        shareKey(src, propertyId, targetId)
    else
        notify(src, ('Gebruik: /%s [woning-id] [server-id]'):format(Config.KeyCommand), 'info')
    end
end)

RegisterCommand('housingreload', function(src)
    if src ~= 0 and not IsPlayerAceAllowed(src, Config.AdminAce) then return end
    print('[thootje-housing] Config woningen staan in config.lua. Herstart de resource om wijzigingen te laden.')
end)

AddEventHandler('playerDropped', function()
    ActiveHomes[source] = nil
end)

CreateThread(function()
    while true do
        Wait(Config.RentCheckMinutes * 60000)
        local expired = MySQL.query.await('SELECT property_id, owner_identifier FROM thootje_housing_ownership WHERE rent_until IS NOT NULL AND rent_until < ?', { os.time() }) or {}
        for _, row in ipairs(expired) do
            MySQL.update.await('DELETE FROM thootje_housing_keys WHERE property_id = ?', { row.property_id })
            MySQL.update.await('DELETE FROM thootje_housing_ownership WHERE property_id = ?', { row.property_id })
        end
    end
end)

exports('HasAccess', hasAccess)
exports('GetPropertyOwner', function(propertyId) return getOwner(propertyId) end)
exports('AddPropertyKey', function(propertyId, ownerIdentifier, holderIdentifier, holderName)
    return MySQL.insert.await('INSERT IGNORE INTO thootje_housing_keys (property_id, owner_identifier, holder_identifier, holder_name) VALUES (?, ?, ?, ?)', { propertyId, ownerIdentifier, holderIdentifier, holderName or 'Onbekend' })
end)
