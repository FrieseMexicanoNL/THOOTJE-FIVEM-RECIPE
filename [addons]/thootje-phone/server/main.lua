local ActiveCalls = {}
local CallByPlayer = {}
local SmsRate = {}

local function notify(src, message, kind)
    TriggerClientEvent('thootje-phone:client:notify', src, message, kind or 'info')
end

local function identifier(src)
    return THPhone.GetIdentifier(src)
end

local function validNumber(number)
    number = tostring(number or ''):gsub('%s+', '')
    if not number:match('^' .. Config.NumberPrefix .. '%d+$') then return false end
    return #number == #Config.NumberPrefix + Config.NumberLength
end

local function getProfileByIdentifier(id)
    return MySQL.single.await('SELECT * FROM thootje_phone_profiles WHERE identifier = ?', { id })
end

local function getProfileByNumber(number)
    return MySQL.single.await('SELECT * FROM thootje_phone_profiles WHERE phone_number = ?', { number })
end

local function ensureProfile(src)
    local id = identifier(src)
    local profile = getProfileByIdentifier(id)
    if profile then
        if profile.player_name ~= THPhone.GetName(src) then
            MySQL.update.await('UPDATE thootje_phone_profiles SET player_name = ? WHERE identifier = ?', { THPhone.GetName(src), id })
            profile.player_name = THPhone.GetName(src)
        end
        return profile
    end

    local number
    for _ = 1, Config.NumberRetryCount do
        local digits = ''
        for i = 1, Config.NumberLength do digits = digits .. tostring(math.random(0, 9)) end
        local candidate = Config.NumberPrefix .. digits
        if not getProfileByNumber(candidate) then number = candidate break end
    end
    if not number then return nil end

    MySQL.insert.await('INSERT INTO thootje_phone_profiles (identifier, player_name, phone_number, wallpaper) VALUES (?, ?, ?, ?)', {
        id, THPhone.GetName(src), number, Config.DefaultWallpaper
    })
    return getProfileByIdentifier(id)
end

local function getContacts(id)
    return MySQL.query.await('SELECT id, contact_name AS name, phone_number AS number FROM thootje_phone_contacts WHERE owner_identifier = ? ORDER BY contact_name ASC', { id }) or {}
end

local function getMessages(id)
    return MySQL.query.await([[
        SELECT id, sender_number, receiver_number, message, UNIX_TIMESTAMP(created_at) AS timestamp,
        CASE WHEN sender_identifier = ? THEN 'out' ELSE 'in' END AS direction,
        CASE WHEN sender_identifier = ? THEN receiver_number ELSE sender_number END AS other_number
        FROM thootje_phone_messages
        WHERE sender_identifier = ? OR receiver_identifier = ?
        ORDER BY id DESC LIMIT 100
    ]], { id, id, id, id }) or {}
end

local function getNotes(id)
    return MySQL.query.await('SELECT id, title, body, updated_at FROM thootje_phone_notes WHERE owner_identifier = ? ORDER BY updated_at DESC', { id }) or {}
end

local function getPhoneData(src)
    local profile = ensureProfile(src)
    if not profile then return notify(src, 'Je telefoonnummer kon niet worden aangemaakt.', 'error') end
    local id = identifier(src)
    TriggerClientEvent('thootje-phone:client:open', src, {
        profile = { number = profile.phone_number, name = profile.player_name, wallpaper = profile.wallpaper },
        contacts = getContacts(id),
        messages = getMessages(id),
        notes = getNotes(id),
        apps = Config.Apps,
        wallpapers = Config.Wallpapers
    })
end

RegisterNetEvent('thootje-phone:server:open', function()
    local src = source
    getPhoneData(src)
end)

RegisterNetEvent('thootje-phone:server:refresh', function()
    local src = source
    local profile = ensureProfile(src)
    if not profile then return end
    TriggerClientEvent('thootje-phone:client:data', src, {
        contacts = getContacts(identifier(src)),
        messages = getMessages(identifier(src)),
        notes = getNotes(identifier(src))
    })
end)

RegisterNetEvent('thootje-phone:server:addContact', function(name, number)
    local src = source
    local id = identifier(src)
    name = tostring(name or ''):sub(1, 40)
    number = tostring(number or ''):gsub('%s+', '')
    if name == '' or not validNumber(number) or not getProfileByNumber(number) then
        return notify(src, Config.Text.invalid_number, 'error')
    end
    local count = MySQL.scalar.await('SELECT COUNT(*) FROM thootje_phone_contacts WHERE owner_identifier = ?', { id }) or 0
    if count >= Config.MaxContacts then return notify(src, Config.Text.too_many_contacts, 'error') end
    MySQL.insert.await('INSERT INTO thootje_phone_contacts (owner_identifier, contact_name, phone_number) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE contact_name = VALUES(contact_name)', { id, name, number })
    TriggerClientEvent('thootje-phone:client:data', src, { contacts = getContacts(id) })
    notify(src, 'Contact opgeslagen.', 'success')
end)

RegisterNetEvent('thootje-phone:server:deleteContact', function(contactId)
    local src = source
    local id = identifier(src)
    MySQL.update.await('DELETE FROM thootje_phone_contacts WHERE id = ? AND owner_identifier = ?', { tonumber(contactId), id })
    TriggerClientEvent('thootje-phone:client:data', src, { contacts = getContacts(id) })
end)

local function sendSmsFromSource(src, number, message, external)
    local id = identifier(src)
    local profile = ensureProfile(src)
    if not profile then return false end
    number = tostring(number or ''):gsub('%s+', '')
    message = tostring(message or '')
    if not validNumber(number) then
        if not external then notify(src, Config.Text.invalid_number, 'error') end
        return false
    end
    if #message < 1 or #message > Config.MaxSmsLength then
        if not external then notify(src, Config.Text.message_too_long, 'error') end
        return false
    end
    local now = os.time()
    SmsRate[id] = SmsRate[id] or {}
    local recent = {}
    for _, t in ipairs(SmsRate[id]) do if now - t < 60 then recent[#recent + 1] = t end end
    SmsRate[id] = recent
    if #recent >= Config.MaxMessagesPerMinute then
        if not external then notify(src, Config.Text.message_rate, 'error') end
        return false
    end
    SmsRate[id][#SmsRate[id] + 1] = now

    local receiver = getProfileByNumber(number)
    if not receiver then
        if not external then notify(src, Config.Text.not_found, 'error') end
        return false
    end
    MySQL.insert.await('INSERT INTO thootje_phone_messages (sender_identifier, receiver_identifier, sender_number, receiver_number, message) VALUES (?, ?, ?, ?, ?)', {
        id, receiver.identifier, profile.phone_number, number, message
    })
    for _, playerId in ipairs(GetPlayers()) do
        local target = tonumber(playerId)
        if identifier(target) == receiver.identifier then
            TriggerClientEvent('thootje-phone:client:newMessage', target, {
                sender = profile.phone_number, message = message, name = profile.player_name
            })
            notify(target, 'Nieuw sms-bericht van ' .. profile.phone_number, 'info')
            break
        end
    end
    TriggerClientEvent('thootje-phone:client:data', src, { messages = getMessages(id) })
    if not external then notify(src, 'Bericht verzonden.', 'success') end
    return true
end

RegisterNetEvent('thootje-phone:server:sendMessage', function(number, message)
    sendSmsFromSource(source, number, message, false)
end)

local function endCall(callId, reason)
    local call = ActiveCalls[callId]
    if not call then return end
    for _, player in ipairs({ call.from, call.to }) do
        CallByPlayer[player] = nil
        TriggerClientEvent('thootje-phone:client:callEnded', player, reason or Config.Text.call_ended)
    end
    ActiveCalls[callId] = nil
end

RegisterNetEvent('thootje-phone:server:startCall', function(number)
    local src = source
    local profile = ensureProfile(src)
    if not profile then return end
    number = tostring(number or ''):gsub('%s+', '')
    if not validNumber(number) then return notify(src, Config.Text.invalid_number, 'error') end
    local receiver = getProfileByNumber(number)
    if not receiver then return notify(src, Config.Text.not_found, 'error') end
    local target
    for _, playerId in ipairs(GetPlayers()) do
        local p = tonumber(playerId)
        if identifier(p) == receiver.identifier then target = p break end
    end
    if not target then return notify(src, 'Deze speler is momenteel offline.', 'error') end
    if target == src then return notify(src, 'Je kunt jezelf niet bellen.', 'error') end
    if CallByPlayer[src] or CallByPlayer[target] then return notify(src, Config.Text.call_busy, 'error') end

    local callId = ('%s_%s_%s'):format(src, target, os.time())
    local channel = Config.CallChannelBase + (math.abs(joaat(callId)) % 20000)
    ActiveCalls[callId] = { from = src, to = target, channel = channel, started = os.time(), status = 'ringing' }
    CallByPlayer[src], CallByPlayer[target] = callId, callId
    TriggerClientEvent('thootje-phone:client:outgoingCall', src, { callId = callId, number = number, channel = channel })
    TriggerClientEvent('thootje-phone:client:incomingCall', target, { callId = callId, number = profile.phone_number, name = profile.player_name })
    SetTimeout(30000, function()
        if ActiveCalls[callId] and ActiveCalls[callId].status == 'ringing' then endCall(callId, Config.Text.call_no_answer) end
    end)
end)

RegisterNetEvent('thootje-phone:server:answerCall', function(callId)
    local src = source
    local call = ActiveCalls[tostring(callId)]
    if not call or call.to ~= src or call.status ~= 'ringing' then return end
    call.status = 'active'
    call.started = os.time()
    TriggerClientEvent('thootje-phone:client:callConnected', call.from, { channel = call.channel, number = THPhone.GetName(src) })
    TriggerClientEvent('thootje-phone:client:callConnected', call.to, { channel = call.channel, number = THPhone.GetName(call.from) })
end)

RegisterNetEvent('thootje-phone:server:declineCall', function(callId)
    local call = ActiveCalls[tostring(callId)]
    if not call or (call.from ~= source and call.to ~= source) then return end
    endCall(tostring(callId), 'Gesprek geweigerd of beëindigd.')
end)

RegisterNetEvent('thootje-phone:server:hangup', function()
    local callId = CallByPlayer[source]
    if callId then endCall(callId, Config.Text.call_ended) end
end)

RegisterNetEvent('thootje-phone:server:saveWallpaper', function(wallpaper)
    local src = source
    if not Config.Wallpapers[wallpaper] then return end
    MySQL.update.await('UPDATE thootje_phone_profiles SET wallpaper = ? WHERE identifier = ?', { wallpaper, identifier(src) })
    TriggerClientEvent('thootje-phone:client:wallpaper', src, wallpaper)
end)

RegisterNetEvent('thootje-phone:server:saveNote', function(noteId, title, body)
    local src = source
    local id = identifier(src)
    title = tostring(title or 'Notitie'):sub(1, 60)
    body = tostring(body or ''):sub(1, 4000)
    if title == '' then title = 'Notitie' end
    if tonumber(noteId) and tonumber(noteId) > 0 then
        MySQL.update.await('UPDATE thootje_phone_notes SET title = ?, body = ? WHERE id = ? AND owner_identifier = ?', { title, body, tonumber(noteId), id })
    else
        MySQL.insert.await('INSERT INTO thootje_phone_notes (owner_identifier, title, body) VALUES (?, ?, ?)', { id, title, body })
    end
    TriggerClientEvent('thootje-phone:client:data', src, { notes = getNotes(id) })
end)

RegisterNetEvent('thootje-phone:server:deleteNote', function(noteId)
    local src = source
    local id = identifier(src)
    MySQL.update.await('DELETE FROM thootje_phone_notes WHERE id = ? AND owner_identifier = ?', { tonumber(noteId), id })
    TriggerClientEvent('thootje-phone:client:data', src, { notes = getNotes(id) })
end)

AddEventHandler('playerDropped', function()
    local src = source
    local callId = CallByPlayer[src]
    if callId then endCall(callId, 'De verbinding is verbroken.') end
    SmsRate[identifier(src)] = nil
end)

exports('GetPhoneNumber', function(src)
    local profile = ensureProfile(src)
    return profile and profile.phone_number or nil
end)
exports('SendMessage', function(senderSource, targetNumber, message)
    return sendSmsFromSource(tonumber(senderSource), targetNumber, message, true)
end)
