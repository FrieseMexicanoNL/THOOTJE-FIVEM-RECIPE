THOOTJE_SHOPS = {}

local function debugPrint(...)
    if Config.Debug then print('[thootje-shops]', ...) end
end

function THOOTJE_SHOPS.GetIdentifier(src)
    local ok, data = pcall(function()
        return exports['thootje-core']:GetPlayerData(src)
    end)

    if ok and type(data) == 'table' then
        return data.citizenid or data.charid or data.identifier or data.license
    end

    for _, identifier in ipairs(GetPlayerIdentifiers(src)) do
        if identifier:sub(1, 8) == 'license:' then return identifier end
    end
    return nil
end

function THOOTJE_SHOPS.GetInventory(src)
    local ok, inventory = pcall(function()
        return exports['thootje-inventory']:GetInventory(src)
    end)
    if ok then return inventory end
    debugPrint('GetInventory export kon niet worden aangeroepen:', inventory)
    return nil
end

function THOOTJE_SHOPS.AddItem(src, item, amount)
    local ok, result = pcall(function()
        return exports['thootje-inventory']:AddItem(src, item, amount)
    end)
    return ok and result ~= false
end

function THOOTJE_SHOPS.RemoveItem(src, item, amount)
    local ok, result = pcall(function()
        return exports['thootje-inventory']:RemoveItem(src, item, amount)
    end)
    return ok and result ~= false
end

function THOOTJE_SHOPS.Notify(src, message, kind)
    TriggerClientEvent('thootje-core:client:notify', src, message, kind or 'info')
end

function THOOTJE_SHOPS.CountItem(src, item)
    local inventory = THOOTJE_SHOPS.GetInventory(src)
    if type(inventory) ~= 'table' then return 0 end

    -- Supports common inventory layouts: array of slots or {items = {...}}.
    local items = inventory.items or inventory
    local count = 0
    for _, entry in pairs(items) do
        if type(entry) == 'table' and (entry.name == item or entry.item == item) then
            count = count + (tonumber(entry.amount or entry.count or entry.quantity) or 0)
        end
    end
    return count
end
