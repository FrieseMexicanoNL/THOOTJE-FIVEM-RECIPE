THOOTJE_EMS = {}

function THOOTJE_EMS.GetIdentifier(src)
    local ok, data = pcall(function()
        return exports['thootje-core']:GetPlayerData(src)
    end)
    if ok and type(data) == 'table' then
        return data.citizenid or data.charid or data.characterId or data.identifier or data.license
    end
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if id:sub(1, 8) == 'license:' then return id end
    end
    return nil
end

function THOOTJE_EMS.GetCharacterName(src)
    local ok, data = pcall(function()
        return exports['thootje-core']:GetPlayerData(src)
    end)
    if ok and type(data) == 'table' then
        if data.charinfo then
            local name = ((data.charinfo.firstname or '') .. ' ' .. (data.charinfo.lastname or '')):gsub('^%s*(.-)%s*$', '%1')
            if name ~= '' then return name end
        end
        return data.fullname or data.name or GetPlayerName(src) or 'Onbekend'
    end
    return GetPlayerName(src) or 'Onbekend'
end

function THOOTJE_EMS.GetJob(src)
    local ok, job = pcall(function()
        return exports['thootje-jobs']:GetJob(src)
    end)
    if ok and type(job) == 'table' then
        return {
            name = job.name or job.job,
            grade = tonumber(job.grade) or 0,
            gradeLabel = job.gradeLabel or job.gradeName or 'Medewerker',
            label = job.label or Config.JobLabel,
            onduty = job.onduty == true or job.onDuty == true,
            isBoss = job.isBoss == true
        }
    end

    local state = Player(src) and Player(src).state
    local jobData = state and state.thootjeJob
    if type(jobData) == 'table' then
        return {
            name = jobData.name or jobData.job,
            grade = tonumber(jobData.grade) or 0,
            gradeLabel = jobData.gradeLabel or 'Medewerker',
            label = jobData.label or Config.JobLabel,
            onduty = jobData.onduty == true or jobData.onDuty == true,
            isBoss = jobData.isBoss == true
        }
    end
    return nil
end

function THOOTJE_EMS.IsMedic(src, permission)
    if not GetPlayerName(src) then return false, 'offline' end
    local job = THOOTJE_EMS.GetJob(src)
    if not job or job.name ~= Config.JobName then return false, 'job' end
    if Config.RequireDuty and not job.onduty then return false, 'duty' end
    local minGrade = Config.Permissions[permission] or 0
    if job.grade < minGrade then return false, 'grade' end
    return true, job.grade, job
end

function THOOTJE_EMS.GetInventory(src)
    local ok, inventory = pcall(function()
        return exports['thootje-inventory']:GetInventory(src)
    end)
    if not ok or type(inventory) ~= 'table' then return nil end
    return inventory
end

function THOOTJE_EMS.HasItem(src, itemName, amount)
    amount = math.max(1, math.floor(tonumber(amount) or 1))
    local inventory = THOOTJE_EMS.GetInventory(src)
    if not inventory then return false end
    local count = 0
    for _, slot in pairs(inventory) do
        if type(slot) == 'table' and slot.name == itemName then
            count = count + (tonumber(slot.count) or 0)
        end
    end
    return count >= amount
end

function THOOTJE_EMS.RemoveItem(src, itemName, amount)
    local ok, result = pcall(function()
        return exports['thootje-inventory']:RemoveItem(src, itemName, amount)
    end)
    return ok and result == true
end

function THOOTJE_EMS.CreateInvoice(sender, recipient, amount, description)
    local ok, success, invoiceId, invoiceNumber = pcall(function()
        return exports['thootje-billing']:CreateInvoice(sender, recipient, amount, description, {
            noFee = true,
            noPayout = true,
            senderName = 'Ambulancedienst',
            requireNearby = false
        })
    end)
    if not ok then return false, 'billing_unavailable' end
    if success ~= true then return false, invoiceId or 'invoice_failed' end
    return true, invoiceId, invoiceNumber
end

function THOOTJE_EMS.Notify(src, message, kind)
    TriggerClientEvent(Config.NotifyEvent, src, message, kind or 'info')
end
