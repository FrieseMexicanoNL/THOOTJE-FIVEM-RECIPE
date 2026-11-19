local function getShop(shopId)
    return Config.Shops[shopId]
end

local function isNearShop(src, shop)
    if not Config.RequireShopDistance then return true end
    local ped = GetPlayerPed(src)
    if ped == 0 then return false end
    local coords = GetEntityCoords(ped)
    return #(coords - shop.coords) <= (Config.InteractDistance + 3.0)
end

local function findProduct(list, item)
    for _, product in ipairs(list or {}) do
        if product.item == item then return product end
    end
    return nil
end

local function validAmount(amount)
    return amount and amount >= 1 and amount <= Config.MaxTransactionAmount and amount == math.floor(amount)
end

local function logTransaction(src, shopId, action, item, amount, total)
    if not Config.TransactionLog then return end
    local identifier = THOOTJE_SHOPS.GetIdentifier(src)
    MySQL.insert('INSERT INTO thootje_shop_transactions (identifier, player_name, shop_id, action, item, amount, total) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        identifier or 'unknown', GetPlayerName(src) or 'Unknown', shopId, action, item, amount, total
    })
end

RegisterNetEvent('thootje-shops:server:openShop', function(shopId)
    local src = source
    local shop = getShop(shopId)
    if not shop or not isNearShop(src, shop) then
        TriggerClientEvent('thootje-shops:client:notify', src, Config.Locale.tooFar)
        return
    end

    local function cleanProducts(products)
        local output = {}
        for _, p in ipairs(products or {}) do
            output[#output + 1] = {
                item = p.item, label = p.label or p.item, price = p.price,
                category = p.category or 'Overig', description = p.description or ''
            }
        end
        return output
    end

    TriggerClientEvent('thootje-shops:client:openShop', src, shopId, {
        label = shop.label, subtitle = shop.subtitle or '', type = shop.type or 'shop',
        buy = cleanProducts(shop.buy), sell = cleanProducts(shop.sell),
        currency = Config.Currency.symbol
    })
end)

RegisterNetEvent('thootje-shops:server:buy', function(shopId, item, amount)
    local src = source
    local shop = getShop(shopId)
    amount = tonumber(amount)
    if not shop or not isNearShop(src, shop) or not validAmount(amount) or type(item) ~= 'string' then
        TriggerClientEvent('thootje-shops:client:notify', src, Config.Locale.invalid)
        return
    end

    local product = findProduct(shop.buy, item)
    if not product then TriggerClientEvent('thootje-shops:client:notify', src, Config.Locale.invalid); return end

    local total = math.floor((tonumber(product.price) or 0) * amount)
    if total <= 0 then return end

    if THOOTJE_SHOPS.CountItem(src, Config.Currency.item) < total then
        TriggerClientEvent('thootje-shops:client:notify', src, Config.Locale.noMoney)
        return
    end

    if not THOOTJE_SHOPS.RemoveItem(src, Config.Currency.item, total) then
        TriggerClientEvent('thootje-shops:client:notify', src, Config.Locale.noMoney)
        return
    end

    if not THOOTJE_SHOPS.AddItem(src, item, amount) then
        THOOTJE_SHOPS.AddItem(src, Config.Currency.item, total)
        TriggerClientEvent('thootje-shops:client:notify', src, Config.Locale.inventoryFull)
        return
    end

    logTransaction(src, shopId, 'buy', item, amount, total)
    TriggerClientEvent('thootje-shops:client:notify', src, Config.Locale.bought)
end)

RegisterNetEvent('thootje-shops:server:sell', function(shopId, item, amount)
    local src = source
    local shop = getShop(shopId)
    amount = tonumber(amount)
    if not shop or not isNearShop(src, shop) or not validAmount(amount) or type(item) ~= 'string' then
        TriggerClientEvent('thootje-shops:client:notify', src, Config.Locale.invalid)
        return
    end

    local product = findProduct(shop.sell, item)
    if not product then TriggerClientEvent('thootje-shops:client:notify', src, Config.Locale.invalid); return end
    if THOOTJE_SHOPS.CountItem(src, item) < amount then
        TriggerClientEvent('thootje-shops:client:notify', src, Config.Locale.noItem)
        return
    end

    local total = math.floor((tonumber(product.price) or 0) * amount * Config.SellMultiplier)
    if total <= 0 then return end
    if not THOOTJE_SHOPS.RemoveItem(src, item, amount) then
        TriggerClientEvent('thootje-shops:client:notify', src, Config.Locale.noItem)
        return
    end
    if not THOOTJE_SHOPS.AddItem(src, Config.Currency.item, total) then
        THOOTJE_SHOPS.AddItem(src, item, amount)
        TriggerClientEvent('thootje-shops:client:notify', src, Config.Locale.inventoryFull)
        return
    end

    logTransaction(src, shopId, 'sell', item, amount, total)
    TriggerClientEvent('thootje-shops:client:notify', src, Config.Locale.sold)
end)

exports('GetShops', function() return Config.Shops end)
exports('OpenShop', function(src, shopId)
    TriggerEvent('thootje-shops:server:openShop', shopId)
end)
