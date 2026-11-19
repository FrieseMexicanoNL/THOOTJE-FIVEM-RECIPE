local function isAdmin(src)
    if src == 0 then return true end
    local p = Thootje.Players[src]
    return p and Config.AdminGroups[p.group] == true
end

RegisterCommand(Config.Commands.cash, function(src)
    local p = Thootje.Players[src]
    if not p then return end
    TriggerClientEvent('chat:addMessage', src, {
        color = {80, 200, 120}, args = {'THOOTJE', ('Contant: €%s | Bank: €%s'):format(p.accounts.cash or 0, p.accounts.bank or 0)}
    })
end, false)

RegisterCommand(Config.Commands.inventory, function(src)
    local p = Thootje.Players[src]
    if p then TriggerClientEvent('thootje:client:openInventory', src, p.inventory) end
end, false)

RegisterCommand(Config.Commands.giveItem, function(src, args)
    if not isAdmin(src) then return end
    local target, item, amount = tonumber(args[1]), args[2], tonumber(args[3]) or 1
    if not target or not Thootje.Players[target] then return end
    local ok, err = Thootje.Functions.AddItem(target, item, amount)
    TriggerClientEvent('chat:addMessage', src, {args = {'THOOTJE', ok and 'Item gegeven.' or (err or 'Mislukt.')}})
end, false)

RegisterCommand(Config.Commands.setJob, function(src, args)
    if not isAdmin(src) then return end
    local target, job = tonumber(args[1]), args[2]
    if not target or not job or not Thootje.Players[target] then return end
    Thootje.Functions.SetJob(target, job, job, tonumber(args[3]) or 0)
end, false)

RegisterCommand(Config.Commands.setMoney, function(src, args)
    if not isAdmin(src) then return end
    local target, account, amount = tonumber(args[1]), args[2], tonumber(args[3])
    local p = target and Thootje.Players[target]
    if not p or not amount or p.accounts[account] == nil then return end
    p.accounts[account] = math.max(0, math.floor(amount))
    TriggerClientEvent('thootje:client:updateData', target, Thootje.GetPlayerData(target))
end, false)
