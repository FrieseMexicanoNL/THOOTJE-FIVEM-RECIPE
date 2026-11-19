local function notify(src,msg,kind) THOOTJE_BILLING.Notify(src,msg,kind) end
local function makeInvoiceNumber(id)
    return ('%s-%06d'):format(Config.InvoicePrefix, id)
end

local function fetchInvoices(identifier)
    return MySQL.query.await([[
        SELECT id, invoice_number, sender_identifier, sender_name, recipient_identifier,
        recipient_name, description, amount, fee, total, status, created_at, expires_at
        FROM thootje_billing_invoices
        WHERE sender_identifier = ? OR recipient_identifier = ?
        ORDER BY id DESC LIMIT 100
    ]],{identifier,identifier}) or {}
end

local function sendData(src)
    local identifier=THOOTJE_BILLING.GetIdentifier(src)
    if not identifier then return end
    TriggerClientEvent('thootje-billing:client:open',src,{
        invoices=fetchInvoices(identifier),
        playerName=THOOTJE_BILLING.GetCharacterName(src),
        identifier=THOOTJE_BILLING.GetIdentifier(src),
        paymentMethod=Config.PaymentMethod,
        currency=Config.CurrencySymbol
    })
end

RegisterNetEvent('thootje-billing:server:requestData',function()
    sendData(source)
end)

RegisterNetEvent('thootje-billing:server:create',function(data)
    local src=source
    if type(data)~='table' then return end
    local target=tonumber(data.target)
    local amount=math.floor(tonumber(data.amount) or 0)
    local description=tostring(data.description or ''):sub(1,Config.MaxDescriptionLength)
    if not target or target==src and not Config.AllowSelfInvoice or not GetPlayerName(target)
        or amount<1 or amount>Config.MaxInvoiceAmount or #description<3 then
        notify(src,Config.Locale.invalid,'error'); return
    end
    if Config.RequireNearbyRecipient then
        local p1,p2=GetPlayerPed(src),GetPlayerPed(target)
        if p1==0 or p2==0 or #(GetEntityCoords(p1)-GetEntityCoords(p2))>Config.NearbyDistance then
            notify(src,Config.Locale.tooFar,'error'); return
        end
    end
    local senderId=THOOTJE_BILLING.GetIdentifier(src)
    local recipientId=THOOTJE_BILLING.GetIdentifier(target)
    if not senderId or not recipientId then notify(src,Config.Locale.invalid,'error'); return end
    local openCount=MySQL.scalar.await("SELECT COUNT(*) FROM thootje_billing_invoices WHERE sender_identifier=? AND status='open'",{senderId}) or 0
    if openCount>=Config.MaxOpenInvoices then notify(src,'Je hebt te veel openstaande facturen.','error'); return end
    local fee=math.floor(amount*(Config.InvoiceFeePercent/100))
    local total=amount+fee
    local id=MySQL.insert.await([[
        INSERT INTO thootje_billing_invoices
        (sender_identifier,sender_name,recipient_identifier,recipient_name,description,amount,fee,total,status,expires_at)
        VALUES (?,?,?,?,?,?,?,?, 'open', DATE_ADD(NOW(), INTERVAL ? DAY))
    ]],{senderId,THOOTJE_BILLING.GetCharacterName(src),recipientId,THOOTJE_BILLING.GetCharacterName(target),description,amount,fee,total,Config.InvoiceExpiryDays})
    local number=makeInvoiceNumber(id)
    MySQL.update.await('UPDATE thootje_billing_invoices SET invoice_number=? WHERE id=?',{number,id})
    notify(src,Config.Locale.sent,'success')
    notify(target,('Je hebt een nieuwe factuur ontvangen: %s (%s%s)'):format(number,Config.CurrencySymbol,total),'info')
    TriggerClientEvent('thootje-billing:client:update',src,{invoices=fetchInvoices(senderId)})
    TriggerClientEvent('thootje-billing:client:update',target,{invoices=fetchInvoices(recipientId)})
end)

RegisterNetEvent('thootje-billing:server:pay',function(id)
    local src=source
    id=tonumber(id)
    if not id then return end
    local identifier=THOOTJE_BILLING.GetIdentifier(src)
    local invoice=MySQL.single.await('SELECT * FROM thootje_billing_invoices WHERE id=?',{id})
    if not invoice then notify(src,Config.Locale.notFound,'error'); return end
    if invoice.recipient_identifier~=identifier then notify(src,Config.Locale.notYours,'error'); return end
    if invoice.status~='open' then notify(src,Config.Locale.alreadyHandled,'error'); return end
    if invoice.expires_at and os.time() > (os.time() + 1) then end -- DB expiry is checked below.
    local expired=MySQL.scalar.await("SELECT (expires_at < NOW()) FROM thootje_billing_invoices WHERE id=?",{id})
    if tonumber(expired)==1 then
        MySQL.update.await("UPDATE thootje_billing_invoices SET status='expired' WHERE id=? AND status='open'",{id})
        notify(src,Config.Locale.expired,'error'); return
    end
    local balance=THOOTJE_BILLING.GetBalance(src)
    if Config.PaymentMethod=='bank' then
        if not balance or balance<invoice.total then notify(src,Config.Locale.insufficient,'error'); return end
        if not THOOTJE_BILLING.RemoveBank(src,invoice.total) then notify(src,Config.Locale.insufficient,'error'); return end
    else
        -- Cash mode expects the inventory bridge to be added by server owner.
        notify(src,'Contante betaling is nog niet gekoppeld. Gebruik bankbetaling.','error'); return
    end

    local changed=MySQL.update.await("UPDATE thootje_billing_invoices SET status='paid', paid_at=NOW(), paid_by=? WHERE id=? AND status='open'",{identifier,id})
    if changed~=1 then
        THOOTJE_BILLING.AddBank(src,invoice.total)
        notify(src,Config.Locale.alreadyHandled,'error'); return
    end

    if tonumber(invoice.no_payout) ~= 1 then
        local senderSource
        for _,player in ipairs(GetPlayers()) do
            local p=tonumber(player)
            if THOOTJE_BILLING.GetIdentifier(p)==invoice.sender_identifier then senderSource=p; break end
        end
        if senderSource then
            local credited=THOOTJE_BILLING.AddBank(senderSource,invoice.total)
            if not credited then
                print(('[thootje-billing] WAARSCHUWING: betaling factuur %s is afgeschreven, maar crediteren aan verzender mislukte.'):format(invoice.invoice_number))
            end
            notify(senderSource,('Factuur %s is betaald.'):format(invoice.invoice_number),'success')
        else
            MySQL.insert.await('INSERT INTO thootje_billing_payouts (identifier, amount, invoice_id) VALUES (?,?,?)',{invoice.sender_identifier,invoice.total,id})
        end
    else
        print(('[thootje-billing] Politieboete %s is betaald; persoonlijke uitbetaling overgeslagen.'):format(invoice.invoice_number))
    end
    notify(src,Config.Locale.paid,'success')
    TriggerClientEvent('thootje-billing:client:update',src,{invoices=fetchInvoices(identifier)})
end)

RegisterNetEvent('thootje-billing:server:reject',function(id)
    local src=source
    local identifier=THOOTJE_BILLING.GetIdentifier(src)
    local changed=MySQL.update.await("UPDATE thootje_billing_invoices SET status='rejected', rejected_at=NOW() WHERE id=? AND recipient_identifier=? AND status='open'",{id,identifier})
    if changed==1 then
        notify(src,Config.Locale.rejected,'info')
        local inv=MySQL.single.await('SELECT sender_identifier FROM thootje_billing_invoices WHERE id=?',{id})
        if inv then
            for _,player in ipairs(GetPlayers()) do
                local p=tonumber(player)
                if THOOTJE_BILLING.GetIdentifier(p)==inv.sender_identifier then notify(p,'Een factuur is afgewezen.','error') end
            end
        end
        TriggerClientEvent('thootje-billing:client:update',src,{invoices=fetchInvoices(identifier)})
    else notify(src,Config.Locale.notYours,'error') end
end)

AddEventHandler('playerJoining',function()
    local src=source
    SetTimeout(5000,function()
        if not GetPlayerName(src) then return end
        local identifier=THOOTJE_BILLING.GetIdentifier(src)
        if not identifier then return end
        local payouts=MySQL.query.await('SELECT id,amount,invoice_id FROM thootje_billing_payouts WHERE identifier=? ORDER BY id ASC',{identifier}) or {}
        for _,payout in ipairs(payouts) do
            if THOOTJE_BILLING.AddBank(src,tonumber(payout.amount)) then
                MySQL.update.await('DELETE FROM thootje_billing_payouts WHERE id=?',{payout.id})
                notify(src,('Je hebt een openstaande factuurbetaling ontvangen: %s%s'):format(Config.CurrencySymbol,payout.amount),'success')
            else
                break
            end
        end
    end)
end)

exports('GetInvoices',function(identifier) return fetchInvoices(identifier) end)


-- Trusted server-resource API: creates a standard invoice visible in THOOTJE-BILLING.
local function createExternalInvoice(senderSource, recipientSource, amount, description, options)
    senderSource, recipientSource = tonumber(senderSource), tonumber(recipientSource)
    amount = math.floor(tonumber(amount) or 0)
    description = tostring(description or ''):sub(1, Config.MaxDescriptionLength)
    options = type(options) == 'table' and options or {}
    if not senderSource or not recipientSource or senderSource == recipientSource
        or not GetPlayerName(senderSource) or not GetPlayerName(recipientSource)
        or amount < 1 or amount > Config.MaxInvoiceAmount or #description < 3 then
        return false, 'invalid'
    end
    local senderId = THOOTJE_BILLING.GetIdentifier(senderSource)
    local recipientId = THOOTJE_BILLING.GetIdentifier(recipientSource)
    if not senderId or not recipientId then return false, 'identifier' end
    if options.requireNearby == true and Config.RequireNearbyRecipient then
        local p1, p2 = GetPlayerPed(senderSource), GetPlayerPed(recipientSource)
        if p1 == 0 or p2 == 0 or #(GetEntityCoords(p1) - GetEntityCoords(p2)) > Config.NearbyDistance then
            return false, 'too_far'
        end
    end
    local openCount = MySQL.scalar.await(
        "SELECT COUNT(*) FROM thootje_billing_invoices WHERE sender_identifier=? AND status='open'", { senderId }
    ) or 0
    if openCount >= Config.MaxOpenInvoices then return false, 'too_many_open' end
    local fee = options.noFee == true and 0 or math.floor(amount * (Config.InvoiceFeePercent / 100))
    local total = amount + fee
    local senderName = tostring(options.senderName or THOOTJE_BILLING.GetCharacterName(senderSource)):sub(1, 100)
    local recipientName = tostring(THOOTJE_BILLING.GetCharacterName(recipientSource)):sub(1, 100)
    local id = MySQL.insert.await([[
        INSERT INTO thootje_billing_invoices
        (sender_identifier,sender_name,recipient_identifier,recipient_name,description,amount,fee,total,status,expires_at,no_payout)
        VALUES (?,?,?,?,?,?,?,?, 'open', DATE_ADD(NOW(), INTERVAL ? DAY), ?)
    ]], { senderId, senderName, recipientId, recipientName, description, amount, fee, total, Config.InvoiceExpiryDays, options.noPayout == true and 1 or 0 })
    if not id then return false, 'database' end
    local number = makeInvoiceNumber(id)
    MySQL.update.await('UPDATE thootje_billing_invoices SET invoice_number=? WHERE id=?', { number, id })
    notify(senderSource, ('Factuur %s aangemaakt.'):format(number), 'success')
    notify(recipientSource, ('Je hebt een nieuwe factuur ontvangen: %s (%s%s)'):format(number, Config.CurrencySymbol, total), 'info')
    TriggerClientEvent('thootje-billing:client:update', senderSource, { invoices = fetchInvoices(senderId) })
    TriggerClientEvent('thootje-billing:client:update', recipientSource, { invoices = fetchInvoices(recipientId) })
    return true, id, number
end
exports('CreateInvoice', createExternalInvoice)
