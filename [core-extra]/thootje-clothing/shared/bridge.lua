THOOTJE_CLOTHING = {}

function THOOTJE_CLOTHING.Identifier(src)
    local ok,data=pcall(function() return exports['thootje-core']:GetPlayerData(src) end)
    if ok and data then return data.citizenid or data.charid or data.identifier or data.license end
    for _,v in ipairs(GetPlayerIdentifiers(src)) do
        if v:find('license:')==1 then return v end
    end
    return nil
end

function THOOTJE_CLOTHING.Notify(src,msg,typ)
    TriggerClientEvent('ox_lib:notify',src,{title='THOOTJE Clothing',description=msg,type=typ or 'inform'})
end
