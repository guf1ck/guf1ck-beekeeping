

local QBCore = exports['qb-core']:GetCoreObject()


local BeeHives = {}
local ActiveBeehives = {}
local inZone = false
local setDeleteAll = false
local isPlacing = false
local hasShownMessage = false

Citizen.CreateThread(function()
    while true do
        local plyCoords = GetEntityCoords(PlayerPedId())
        if BeeHives == nil then BeeHives = {} end
        for idx, hive in ipairs(BeeHives) do
            if idx % 100 == 0 then
                Wait(0) --Process 100 per frame
            end
            --convert timestamp -> growth percent
            local harvestPercent = getHiveReadyPercent(hive)

            if --[[(#(plyCoords) - #(hive.coords)) < (50.0 + harvestPercent) and]] not setDeleteAll then
                local curStage = getStageFromPercent(harvestPercent)
                local isChanged = (ActiveBeehives[hive.id] and ActiveBeehives[hive.id].stage ~= curStage)
                
                if isChanged then
                    removeBeehive(hive.id)
                end
                if not ActiveBeehives[hive.id] or isChanged then
                    local beeHive = createBeehiveStageAtCoords(curStage, json.decode(hive.coords), hive.heading)
                    ActiveBeehives[hive.id] = {
                        object = beeHive,
                        stage = curStage
                    }
                end
            else
                removeBeehive(hive.id)
            end
        end
        if setDeleteAll then
            BeeHives = {}
            setDeleteAll = false
        end
        Wait(inZone and 500 or 1000)
        -- Wait(2000)
    end
end)

RegisterNetEvent("guf1ck-beehives:setBeehives")
AddEventHandler("guf1ck-beehives:setBeehives", function()
    print("1")
    if not isPlacing then
        if inZone then
            isPlacing = true
            if not hasShownMessage then
                exports['qb-core']:DrawText('<b>[Enter]</b> Colocar <b>[Clique com o botão direito do rato]</b> Cancelar<b>[←/→]</b> Rodar','left')
            end
                placeObject("guf1ck_beehive", function(pPlaced, pCoords, pHeading)
                if pPlaced then
                    TaskStartScenarioInPlace(PlayerPedId(), "WORLD_HUMAN_HAMMERING", 0, true)
                    local finished = exports[HiveConfig.Taskbar]:taskBar(15000, HiveConfig.InstallBeehive)
                    ClearPedTasks(PlayerPedId())
                    if finished == 100 then
                        local plyCoords = GetEntityCoords(PlayerPedId())
                        local offsetCoords = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0, 0.7, 0)
                        local rayHandle = StartExpensiveSynchronousShapeTestLosProbe(offsetCoords.x, offsetCoords.y, offsetCoords.z, offsetCoords.x, offsetCoords.y, offsetCoords.z - 2, 1, 0, 4)
                        local retval, hit, endCoords, _, materialHash, _ = GetShapeTestResultIncludingMaterial(rayHandle)
                        TriggerServerEvent("guf1ck-beekeeping:installHive", pCoords) -- Heading NOTE
                        TriggerServerEvent("beehive:removeItem", "beehive", 1)
                    end
                else
                    QBCore.Functions.Notify('Não colocado ou cancelado.',"error")
                    exports['qb-core']:HideText()
                end
                isPlacing = false
                exports['qb-core']:HideText()
            end)
        else 
            QBCore.Functions.Notify('Tem de se encontrar um sítio melhor para o colocar.',"error")
        end
    end
end)

AddEventHandler("guf1ck-beekeeping:checkBeehive", function()
    Wait(500)
    local pedCoords = GetEntityCoords(PlayerPedId())
    local pEntity = nil
    local x1,y1,z1 = table.unpack(GetEntityCoords(PlayerPedId()))
    for k,v in ipairs(HiveConfig.HiveObjects) do
        local closestObject = GetClosestObjectOfType(x1, y1, z1, 2.0, v.hash, false, false, false)
        if closestObject ~= nil and closestObject ~= 0 then
            pEntity = closestObject
            break
        end
    end
    print("1")
    local hiveId = getHiveId(pEntity)

    if not hiveId then return end
    showHiveMenu(hiveId)
end)


-- AddEventHandler('guf1ck-beekeeping:addQueen', function (data)

--     if item > 0 and not add_queenbee then
--         TaskStartScenarioInPlace(PlayerPedId(), "WORLD_HUMAN_GARDENER_PLANT", 0, true)
--         local finished = exports[HiveConfig.Taskbar]:taskBar(15000, "beequeen")
--         ClearPedTasks(PlayerPedId())
--         if finished == 100 then
--             QBCore.Functions.TriggerCallback('guf1ck-beekeeping:addQueen', function(success) 
--                 if not success then
--                     QBCore.Functions.Notify('Kraliçe Arı Yok!',"error")
--                 else
--                     TriggerServerEvent("beehive:removeItem", "beequeen", 1)
--                     add_queenbee = true
--                 end
--             end, data)
--         end
--     end
-- end)

RegisterNetEvent('guf1ck-beekeeping:Gate')
AddEventHandler('guf1ck-beekeeping:Gate', function()
    QBCore.Functions.TriggerCallback('QBCore:HasItem', function(hasItem)
        if hasItem then
            TriggerEvent('guf1ck-beekeeping:addQueen')			
            Citizen.Wait(1000)
        else
            QBCore.Functions.Notify("Sem Abelha Rainha.", "error")
        end
    end, "beequeen")
end)

local add_queenbee = false

RegisterNetEvent('guf1ck-beekeeping:addQueen')
AddEventHandler('guf1ck-beekeeping:addQueen', function(data)
    TaskStartScenarioInPlace(PlayerPedId(), "WORLD_HUMAN_GARDENER_PLANT", 0, true)
    local finished = exports["gate-taskbar"]:taskBar(5000, "Adicionar Abelha Rainha")
    ClearPedTasks(PlayerPedId())
    if finished == 100 then
        QBCore.Functions.TriggerCallback('guf1ck-beekeeping:addQueen', function(success)
            if not success then
                QBCore.Functions.Notify("Sem Abelha Rainha.", "error")
            else
                TriggerServerEvent("beehive:removeItem", "beequeen", 1)
                add_queenbee = true        
            end
        end, data)
    end
    Wait(200)
end)

AddEventHandler('guf1ck-beekeeping:removeHive', function (data)
    RequestAnimDict("weapons@first_person@aim_rng@generic@projectile@thermal_charge@")
    while not HasAnimDictLoaded("weapons@first_person@aim_rng@generic@projectile@thermal_charge@") do
        Citizen.Wait(7)
    end
    TaskPlayAnim(PlayerPedId(), 'weapons@first_person@aim_rng@generic@projectile@thermal_charge@', "plant_floor", 8.0, -8, -1, 16, 0, 0, 0, 0 )
    local finished = exports[HiveConfig.Taskbar]:taskBar(15000, HiveConfig.RemoveHive)
    ClearPedTasks(PlayerPedId())
    if finished == 100 then
        QBCore.Functions.TriggerCallback('guf1ck-beekeeping:removeHive', function(success) 
            if success then
                removeBeehive(data)
                add_queenbee = false
            end
        end, data)
    end
end)

AddEventHandler("guf1ck-beekeeping:harvestHive", function()
    Wait(500)


    local pedCoords = GetEntityCoords(PlayerPedId())
    local pEntity = nil
    local x1,y1,z1 = table.unpack(GetEntityCoords(PlayerPedId()))
    for k,v in ipairs(HiveConfig.HiveObjects) do
        local closestObject = GetClosestObjectOfType(x1, y1, z1, 30.0, v.hash, false, false, false)
        if closestObject ~= nil and closestObject ~= 0 then
            pEntity = closestObject
            break
        end
    end

    local hiveId = getHiveId(pEntity)
    if not hiveId then return end

    local hive = getHiveById(hiveId)
    local timeSinceHarvest = GetCloudTimeAsInt()
    if getHiveReadyPercent(hive) < HiveConfig.HarvestPercent or timeSinceHarvest <= (HiveConfig.TimeBetweenHarvest * 60) then
        QBCore.Functions.Notify('Mel não pronto para recolha',"error")
        return
    end

    RequestAnimDict("weapons@first_person@aim_rng@generic@projectile@thermal_charge@")
    while not HasAnimDictLoaded("weapons@first_person@aim_rng@generic@projectile@thermal_charge@") do
        Citizen.Wait(7)
    end
    TaskPlayAnim(PlayerPedId(), 'weapons@first_person@aim_rng@generic@projectile@thermal_charge@', "plant_floor", 8.0, -8, -1, 16, 0, 0, 0, 0 )

    local finished = exports[HiveConfig.Taskbar]:taskBar(5000,HiveConfig.HarvestHive)
    ClearPedTasks(PlayerPedId())
    if finished == 100 then
        TriggerServerEvent("guf1ck-beekeeping:harvestHive", hiveId, hive.beequeen)
    end
end)

function loadAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Citizen.Wait(5)
    end
end 

Citizen.CreateThread(function()
    for id,zone in ipairs(HiveZones) do
        exports[HiveConfig.PolyZone]:AddCircleZone("guf1ck-beekeeping:bee_zone", zone[1], zone[2])
    end
end)

AddEventHandler(HiveConfig.PolyZoneEnter, function(zone, data)
    if zone == "guf1ck-beekeeping:bee_zone" then
        inZone = true
        QBCore.Functions.TriggerCallback('guf1ck-beekeeping:getBeehives', function(cb)
            BeeHives = cb
        end)
    end
end)

AddEventHandler(HiveConfig.PolyZoneExit, function(zone, data)
    if zone == "guf1ck-beekeeping:bee_zone" then
        inZone = false
        stopPlacing()
        setDeleteAll = true
    end
end)

RegisterNetEvent('guf1ck-beekeeping:trigger_zone')
AddEventHandler('guf1ck-beekeeping:trigger_zone', function (type, pData)
    --Update all hives
    if type == 1 then
        for _, hive in ipairs(BeeHives) do
            local keep = false
            for _, newhive in ipairs(pData) do
                if hive.id == newhive.id then
                    keep = true
                    break
                end
            end

            if not keep then
                removeBeehive(hive.id)
            end
        end
        BeeHives = pData
    end

    --New hive being added
    if type == 2 then
        BeeHives[#BeeHives+1] = pData
    end

    --hive being harvested/updated
    if type == 3 then
        for idx, hive in ipairs(BeeHives) do
            if hive.id == pData then
                BeeHives[idx] = pData
                break
            end
        end
    end
  
    --hive being removed
    if type == 4 then
        for idx, hive in ipairs(BeeHives) do
            if hive.id == pData then
                table.remove(BeeHives, idx)
                removeBeehive(hive.id)
                break
            end
        end
    end
end)

AddEventHandler("onResourceStop", function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for idx, hive in pairs(ActiveBeehives) do
        DeleteObject(hive.object)
    end
end)

function createBeehiveStageAtCoords(pStage, pCoords, pHeading)
    local model = HiveConfig.HiveObjects[pStage].hash
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end
    local hiveObject = CreateObject(model, pCoords.x, pCoords.y, pCoords.z, 0, 0, 0)
    FreezeEntityPosition(hiveObject, true)
    if not pHeading then pHeading = 0.0 end
    SetEntityHeading(hiveObject, pHeading + 0.00001)
    return hiveObject
end

function removeBeehive(pHiveId)
    if ActiveBeehives[pHiveId] then
        DeleteObject(ActiveBeehives[pHiveId].object)
        ActiveBeehives[pHiveId] = nil
    end
end

function getStageFromPercent(pPercent)
  if pPercent < 50.0 then
    return 1
  elseif pPercent >= 50.0 and pPercent < 100.0 then
    return 2
  else
    return 3
  end
end

function getHiveReadyPercent(pHive)
    --local timeDiff = (GetCloudTimeAsInt() - math.max(pHive.last_harvest, pHive.timestamp)) / 60
    local timeDiff = (GetCloudTimeAsInt() - pHive.timestamp) / 60
    local queenFactor = (pHive.has_queen and HiveConfig.QueenFactor or 1)
    local growthFactors = (HiveConfig.GrowthTime / queenFactor)
    return math.min((timeDiff / growthFactors) * 100, 100.0)
end

function getHiveId(pEntity)
    for hiveId, hive in pairs(ActiveBeehives) do
        if hive.object == pEntity then
            return hiveId
        end
        print("asdad")
    end
end

function getHiveById(pHiveId)
    for _, hive in pairs(BeeHives) do
        if hive.id == pHiveId then
            return hive
        end
    end
end


function showHiveMenu(pHiveId)
    local hive = getHiveById(pHiveId)
    --Buigate context menu
    local harvest = getHiveReadyPercent(hive)
    if add_queenbee then
        text = "<b style='color:green;'>Há uma Abelha Rainha</b>"
    else
        text = "<b style='color:red;'>Sem Abelha Rainha</b>"
    end

    local beemenu = {
        {
            isMenuHeader = true,
            disabled = true,
            icon = "fas fa-box-archive",
            header = "Operações da colmeia",
        },
        {
            id = 1,
            icon = "fas fa-database",
            disabled = true,
            header = "Quantidade de mel: <b>"..string.format("%.2f", harvest) .. '% </b>',
            txt = text,
        }
    }

    if getStageFromPercent(harvest) < 3 then
        beemenu[#beemenu+1] = {
            id = 6,
            header = "Adicionar Abelha Rainha",
            icon = "fas fa-plus-minus",
            txt = "A abelha rainha aumenta o seu rendimento",
            params = {
                event = "guf1ck-beekeeping:Gate",
                args = pHiveId,
            },
        }
    end
    if harvest >= 100 then
        beemenu[#beemenu+1] = {
            id = 7,
            header = "Recolha de culturas",
            icon = "fas fa-check-double",
            txt = "",
            params = {
                event = "guf1ck-beekeeping:harvestHive",
                args = pHiveId,
            },
        }
    end
    Wait(100)

    exports['qb-menu']:openMenu(beemenu)
end

RegisterNetEvent('ananibikezsiktimkudurdu:ananinaminakorum')
AddEventHandler('ananibikezsiktimkudurdu:ananinaminakorum', function()
    TriggerServerEvent("beehive:addItem","beeswax",1)
    TriggerServerEvent("beehive:addItem","honey",1)
    TriggerServerEvent("beehive:addItem","beequeen",1)

end)

RegisterNetEvent('ananibikezsiktimkudurdu:ananinaminakorumm')
AddEventHandler('ananibikezsiktimkudurdu:ananinaminakorumm', function()
    TriggerServerEvent("beehive:addItem","honey",1)
    TriggerServerEvent("beehive:addItem","beeswax",1)
end)

