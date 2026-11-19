local function getIdentifier(src) return THOOTJE_CLOTHING.Identifier(src) end

lib.callback.register('thootje-clothing:server:getOutfits',function(src)
    local identifier=getIdentifier(src)
    if not identifier then return {} end
    return MySQL.query.await('SELECT id,name,created_at FROM thootje_clothing_outfits WHERE owner_identifier=? ORDER BY created_at DESC',{identifier}) or {}
end)

lib.callback.register('thootje-clothing:server:getOutfit',function(src,id)
    local identifier=getIdentifier(src)
    if not identifier then return nil end
    return MySQL.single.await('SELECT id,name,appearance FROM thootje_clothing_outfits WHERE id=? AND owner_identifier=?',{tonumber(id),identifier})
end)

RegisterNetEvent('thootje-clothing:server:saveOutfit',function(name,appearance)
    local src=source
    local identifier=getIdentifier(src)
    if not identifier or type(appearance)~='table' then return end
    name=tostring(name or Config.DefaultOutfitName):gsub('[<>]',''):sub(1,32)
    if name=='' then name=Config.DefaultOutfitName end
    local count=MySQL.scalar.await('SELECT COUNT(*) FROM thootje_clothing_outfits WHERE owner_identifier=?',{identifier}) or 0
    if tonumber(count)>=Config.MaxSavedOutfits then
        THOOTJE_CLOTHING.Notify(src,'Je hebt het maximum aantal opgeslagen outfits bereikt.','error')
        return
    end
    local encoded=json.encode(appearance)
    if #encoded>30000 then THOOTJE_CLOTHING.Notify(src,'Deze outfit bevat te veel gegevens.','error'); return end
    MySQL.insert.await('INSERT INTO thootje_clothing_outfits (owner_identifier,name,appearance) VALUES (?,?,?)',{identifier,name,encoded})
    THOOTJE_CLOTHING.Notify(src,'Outfit opgeslagen in je kledingkast.','success')
    TriggerClientEvent('thootje-clothing:client:refreshOutfits',src)
end)

RegisterNetEvent('thootje-clothing:server:deleteOutfit',function(id)
    local src=source
    local identifier=getIdentifier(src)
    if not identifier then return end
    MySQL.update.await('DELETE FROM thootje_clothing_outfits WHERE id=? AND owner_identifier=?',{tonumber(id),identifier})
    THOOTJE_CLOTHING.Notify(src,'Outfit verwijderd.','success')
    TriggerClientEvent('thootje-clothing:client:refreshOutfits',src)
end)


