RegisterNetEvent('thootje:server:triggerCallback', function(name, requestId, ...)
    local src = source
    local callback = Thootje.Callbacks[name]
    if not callback then
        TriggerClientEvent('thootje:client:callbackResponse', src, requestId, nil)
        return
    end
    callback(src, function(...)
        TriggerClientEvent('thootje:client:callbackResponse', src, requestId, ...)
    end, ...)
end)

function Thootje.RegisterServerCallback(name, callback)
    assert(type(name) == 'string' and type(callback) == 'function', 'Ongeldige callback')
    Thootje.Callbacks[name] = callback
end

exports('RegisterServerCallback', Thootje.RegisterServerCallback)
