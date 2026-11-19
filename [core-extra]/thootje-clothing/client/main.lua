local menuOpen=false
local currentMode='shop'
local originalAppearance=nil
local currentCategory=nil
local function notify(msg,typ) lib.notify({title='THOOTJE Clothing',description=msg,type=typ or 'inform'}) end
local function isFreemode(ped)
    local model=GetEntityModel(ped)
    return model==joaat('mp_m_freemode_01') or model==joaat('mp_f_freemode_01')
end

local function captureAppearance()
    local ped=PlayerPedId()
    local data={model=GetEntityModel(ped),components={},props={}}
    for i=0,11 do
        data.components[tostring(i)]={drawable=GetPedDrawableVariation(ped,i),texture=GetPedTextureVariation(ped,i),palette=GetPedPaletteVariation(ped,i)}
    end
    for i=0,7 do
        data.props[tostring(i)]={drawable=GetPedPropIndex(ped,i),texture=GetPedPropTextureIndex(ped,i)}
    end
    return data
end

local function applyAppearance(data)
    if type(data)~='table' then return end
    local ped=PlayerPedId()
    if data.model and GetEntityModel(ped)~=tonumber(data.model) then
        RequestModel(tonumber(data.model))
        local timeout=GetGameTimer()+5000
        while not HasModelLoaded(tonumber(data.model)) and GetGameTimer()<timeout do Wait(10) end
        if HasModelLoaded(tonumber(data.model)) then
            SetPlayerModel(PlayerId(),tonumber(data.model)); SetModelAsNoLongerNeeded(tonumber(data.model)); ped=PlayerPedId()
        end
    end
    for key,v in pairs(data.components or {}) do
        local id=tonumber(key)
        if id and id>=0 and id<=11 then
            local max=GetNumberOfPedDrawableVariations(ped,id)
            local drawable=math.max(0,math.min(max-1,tonumber(v.drawable) or 0))
            local textures=GetNumberOfPedTextureVariations(ped,id,drawable)
            local texture=math.max(0,math.min(math.max(0,textures-1),tonumber(v.texture) or 0))
            SetPedComponentVariation(ped,id,drawable,texture,tonumber(v.palette) or 0)
        end
    end
    for key,v in pairs(data.props or {}) do
        local id=tonumber(key)
        if id and id>=0 and id<=7 then
            local drawable=tonumber(v.drawable) or -1
            if drawable<0 then ClearPedProp(ped,id) else
                local max=GetNumberOfPedPropDrawableVariations(ped,id)
                drawable=math.max(0,math.min(max-1,drawable))
                local textures=GetNumberOfPedPropTextureVariations(ped,id,drawable)
                local texture=math.max(0,math.min(math.max(0,textures-1),tonumber(v.texture) or 0))
                SetPedPropIndex(ped,id,drawable,texture,true)
            end
        end
    end
end

local function getCategoryState(category)
    local ped=PlayerPedId()
    if category.type=='component' then
        local id=category.component
        return {drawable=GetPedDrawableVariation(ped,id),texture=GetPedTextureVariation(ped,id),maxDrawable=math.max(0,GetNumberOfPedDrawableVariations(ped,id)-1),maxTexture=math.max(0,GetNumberOfPedTextureVariations(ped,id,GetPedDrawableVariation(ped,id))-1)}
    end
    local id=category.prop
    local drawable=GetPedPropIndex(ped,id)
    return {drawable=drawable,texture=drawable<0 and 0 or GetPedPropTextureIndex(ped,id),maxDrawable=math.max(0,GetNumberOfPedPropDrawableVariations(ped,id)-1),maxTexture=drawable<0 and 0 or math.max(0,GetNumberOfPedPropTextureVariations(ped,id,drawable)-1)}
end

local function sendCategory(category)
    currentCategory=category
    SendNUIMessage({action='category',category=category,state=getCategoryState(category)})
end

local function openMenu(mode)
    if menuOpen then return end
    local ped=PlayerPedId()
    if Config.RequireFreemodePed and not isFreemode(ped) then
        notify('Dit kledingmenu werkt met de freemode-personages (mp_m_freemode_01 / mp_f_freemode_01).','error')
        return
    end
    originalAppearance=captureAppearance()
    currentMode=mode or 'shop'
    menuOpen=true
    SetNuiFocus(true,true)
    DisplayRadar(false)
    local outfits=lib.callback.await('thootje-clothing:server:getOutfits',false) or {}
    SendNUIMessage({action='open',mode=currentMode,categories=Config.Categories,outfits=outfits,price=Config.ShopPrice})
    if Config.Categories[1] then sendCategory(Config.Categories[1]) end
end

local function closeMenu()
    if not menuOpen then return end
    menuOpen=false
    SetNuiFocus(false,false)
    DisplayRadar(true)
    SendNUIMessage({action='close'})
end

RegisterCommand(Config.OpenCommand,function() openMenu('shop') end)
RegisterCommand(Config.WardrobeCommand,function() openMenu('wardrobe') end)
RegisterKeyMapping(Config.OpenCommand,'Open THOOTJE kledingwinkel','keyboard',Config.OpenKey)

RegisterCommand(Config.JobWardrobeCommand,function() openJobUniforms() end)
RegisterCommand(Config.HairCommand,function() openHairMenu() end)
RegisterCommand(Config.TattooCommand,function() openTattooMenu() end)
RegisterCommand(Config.FaceCommand,function() openFaceMenu() end)



local function charge(service, price)
    local ok = lib.callback.await('thootje-clothing:server:purchaseService', false, service, price)
    if not ok then notify('Betaling niet gelukt.','error') end
    return ok
end

function openHairMenu()
    if not isFreemode(PlayerPedId()) then notify('Deze kapsalon vereist een freemode-personage.','error'); return end
    local ped=PlayerPedId()
    local current=GetPedDrawableVariation(ped,2)
    local input=lib.inputDialog('THOOTJE Kapsalon', {
        {type='number',label='Kapsel model',default=current,min=0,max=GetNumberOfPedDrawableVariations(ped,2)-1},
        {type='number',label='Haarkleur (0-63)',default=0,min=0,max=63},
        {type='number',label='Highlights (0-63)',default=0,min=0,max=63}
    })
    if not input then return end
    if Config.ChargeForHair and not charge('hair',Config.HairPrice) then return end
    SetPedComponentVariation(ped,2,math.floor(input[1]),0,0)
    SetPedHairColor(ped,math.floor(input[2]),math.floor(input[3]))
    notify('Je nieuwe kapsel is toegepast.','success')
end

function openFaceMenu()
    if not isFreemode(PlayerPedId()) then notify('Gezichtsinstellingen vereisen een freemode-personage.','error'); return end
    local ped=PlayerPedId()
    local names={'Neusbreedte','Neuspunt','Neuslengte','Neusbrug','Neuspunt hoogte','Neus draaien','Wenkbrauw hoogte','Wenkbrauw diepte','Wangen hoogte','Wangen breedte','Wangen breedte 2','Ogen openen','Lippen','Kaakbreedte','Kaakvorm','Kin hoogte','Kinlengte','Kinbreedte','Kin kuiltje','Nekbreedte'}
    local fields={}
    for i=0,19 do fields[#fields+1]={type='number',label=names[i+1],default=math.floor(GetPedFaceFeature(ped,i)*100),min=-100,max=100} end
    local values=lib.inputDialog('THOOTJE Gezichtsstudio',fields)
    if not values then return end
    if Config.ChargeForFace and not charge('face',Config.FacePrice) then return end
    for i=0,19 do SetPedFaceFeature(ped,i,math.max(-1,math.min(1,(tonumber(values[i+1]) or 0)/100))) end
    notify('Gezichtsinstellingen bijgewerkt.','success')
end

function openTattooMenu()
    if not isFreemode(PlayerPedId()) then notify('Tattoos vereisen een freemode-personage.','error'); return end
    local options={}
    local gender=GetEntityModel(PlayerPedId())==joaat('mp_m_freemode_01') and 'male' or 'female'
    for index,tattoo in ipairs(Config.Tattoos or {}) do
        if tattoo.gender==gender or tattoo.gender=='both' then
            options[#options+1]={title=tattoo.label,description='Tatoeage aanbrengen',onSelect=function()
                if Config.ChargeForTattoo and not charge('tattoo',Config.TattooPrice) then return end
                AddPedDecorationFromHashes(PlayerPedId(),joaat(tattoo.collection),joaat(tattoo.name))
                notify('Tattoo aangebracht.','success')
            end}
        end
    end
    options[#options+1]={title='Alle tattoos verwijderen',onSelect=function() ClearPedDecorations(PlayerPedId()); notify('Tattoos verwijderd.','success') end}
    lib.registerContext({id='thootje_tattoos',title='THOOTJE Tattoo Studio',options=options})
    lib.showContext('thootje_tattoos')
end

function openJobUniforms()
    if not isFreemode(PlayerPedId()) then notify('Uniformen vereisen een freemode-personage.','error'); return end
    local jobData
    local ok,data=pcall(function() return exports['thootje-jobs']:GetJob(GetPlayerServerId(PlayerId())) end)
    if ok then jobData=data end
    local jobName=type(jobData)=='table' and (jobData.name or jobData.job) or nil
    local grade=type(jobData)=='table' and tonumber(jobData.grade or 0) or 0
    if not jobName then
        local state=LocalPlayer.state.thootjeJob
        if type(state)=='table' then jobName=state.name or state.job; grade=tonumber(state.grade or 0) end
    end
    local uniform=Config.JobUniforms[jobName]
    if not uniform then notify('Er is geen uniform ingesteld voor jouw baan.','error'); return end
    if grade<(uniform.minGrade or 0) then notify('Je rang heeft geen toegang tot dit uniform.','error'); return end
    local model=GetEntityModel(PlayerPedId())
    local preset=model==joaat('mp_m_freemode_01') and uniform.male or uniform.female
    if not preset then notify('Geen uniform voor dit personage.','error'); return end
    for id,v in pairs(preset.components or {}) do SetPedComponentVariation(PlayerPedId(),tonumber(id),v.drawable or 0,v.texture or 0,0) end
    for id,v in pairs(preset.props or {}) do
        if (v.drawable or -1)<0 then ClearPedProp(PlayerPedId(),tonumber(id)) else SetPedPropIndex(PlayerPedId(),tonumber(id),v.drawable,v.texture or 0,true) end
    end
    notify(uniform.label..' aangetrokken.','success')
end


RegisterNUICallback('close',function(_,cb) closeMenu(); cb(true) end)
RegisterNUICallback('runCommand',function(data,cb)
    local allowed={kapsalon=true,gezicht=true,tattoos=true,joboutfit=true}
    if allowed[data.command] then ExecuteCommand(data.command) end
    cb(true)
end)
RegisterNUICallback('selectCategory',function(data,cb)
    local cat
    for _,v in ipairs(Config.Categories) do if v.id==data.id then cat=v break end end
    if cat then sendCategory(cat) end
    cb(true)
end)
RegisterNUICallback('change',function(data,cb)
    if not currentCategory then cb(false); return end
    local ped=PlayerPedId()
    local drawable=tonumber(data.drawable) or 0
    local texture=tonumber(data.texture) or 0
    if currentCategory.type=='component' then
        local id=currentCategory.component
        local max=GetNumberOfPedDrawableVariations(ped,id)
        drawable=math.max(0,math.min(max-1,drawable))
        local tmax=GetNumberOfPedTextureVariations(ped,id,drawable)
        texture=math.max(0,math.min(math.max(0,tmax-1),texture))
        SetPedComponentVariation(ped,id,drawable,texture,0)
    else
        local id=currentCategory.prop
        if drawable<0 then ClearPedProp(ped,id) else
            local max=GetNumberOfPedPropDrawableVariations(ped,id)
            drawable=math.max(0,math.min(max-1,drawable))
            local tmax=GetNumberOfPedPropTextureVariations(ped,id,drawable)
            texture=math.max(0,math.min(math.max(0,tmax-1),texture))
            SetPedPropIndex(ped,id,drawable,texture,true)
        end
    end
    local state=getCategoryState(currentCategory)
    SendNUIMessage({action='state',state=state})
    cb(state)
end)
RegisterNUICallback('saveOutfit',function(data,cb)
    if currentMode=='shop' and Config.ChargeForShopPurchase then
        local paid=lib.callback.await('thootje-clothing:server:purchaseService',false,'shop',Config.ShopPrice)
        if not paid then cb(false); return end
    end
    TriggerServerEvent('thootje-clothing:server:saveOutfit',data.name or Config.DefaultOutfitName,captureAppearance())
    cb(true)
end)
RegisterNUICallback('loadOutfit',function(data,cb)
    local outfit=lib.callback.await('thootje-clothing:server:getOutfit',false,data.id)
    if outfit and outfit.appearance then applyAppearance(json.decode(outfit.appearance)); cb(true) else cb(false) end
end)
RegisterNUICallback('deleteOutfit',function(data,cb) TriggerServerEvent('thootje-clothing:server:deleteOutfit',data.id); cb(true) end)
RegisterNUICallback('reset',function(_,cb) applyAppearance(originalAppearance); cb(true) end)
RegisterNUICallback('rotate',function(data,cb)
    local ped=PlayerPedId()
    SetEntityHeading(ped,GetEntityHeading(ped)+(tonumber(data.direction) or 0)*15.0)
    cb(true)
end)
RegisterNetEvent('thootje-clothing:client:refreshOutfits',function()
    local outfits=lib.callback.await('thootje-clothing:server:getOutfits',false) or {}
    SendNUIMessage({action='outfits',outfits=outfits})
end)

CreateThread(function()
    while true do
        local wait=1000
        local pos=GetEntityCoords(PlayerPedId())
        for _,shop in ipairs(Config.Shops) do
            local dist=#(pos-shop.coords)
            if dist<Config.MarkerDistance then
                wait=0
                DrawMarker(2,shop.coords.x,shop.coords.y,shop.coords.z+0.15,0,0,0,0,0,0,0.25,0.25,0.25,72,220,198,180,false,true,2,false,nil,nil,false)
                if dist<Config.InteractDistance then
                    lib.showTextUI('[E] '..shop.label)
                    if IsControlJustReleased(0,38) then openMenu('shop') end
                else lib.hideTextUI() end
            end
        end
        for _,wardrobe in ipairs(Config.Wardrobes) do
            local dist=#(pos-wardrobe.coords)
            if dist<Config.MarkerDistance then
                wait=0
                DrawMarker(2,wardrobe.coords.x,wardrobe.coords.y,wardrobe.coords.z+0.15,0,0,0,0,0,0,0.25,0.25,0.25,72,220,198,180,false,true,2,false,nil,nil,false)
                if dist<Config.InteractDistance then
                    lib.showTextUI('[E] '..wardrobe.label)
                    if IsControlJustReleased(0,38) then openMenu('wardrobe') end
                else lib.hideTextUI() end
            end
        end
        Wait(wait)
    end
end)

AddEventHandler('onResourceStop',function(resource)
    if resource==GetCurrentResourceName() then SetNuiFocus(false,false); DisplayRadar(true); lib.hideTextUI() end
end)


CreateThread(function()
    local groups={{list=Config.HairSalons,mode='hair'},{list=Config.TattooShops,mode='tattoo'}}
    while true do
        local wait=1000
        local pos=GetEntityCoords(PlayerPedId())
        for _,group in ipairs(groups) do
            for _,spot in ipairs(group.list or {}) do
                local dist=#(pos-spot.coords)
                if dist<Config.MarkerDistance then
                    wait=0
                    DrawMarker(2,spot.coords.x,spot.coords.y,spot.coords.z+0.15,0,0,0,0,0,0,0.25,0.25,0.25,72,220,198,180,false,true,2,false,nil,nil,false)
                    if dist<Config.InteractDistance then
                        lib.showTextUI('[E] '..spot.label)
                        if IsControlJustReleased(0,38) then
                            if group.mode=='hair' then openHairMenu() else openTattooMenu() end
                        end
                    else lib.hideTextUI() end
                end
            end
        end
        Wait(wait)
    end
end)
