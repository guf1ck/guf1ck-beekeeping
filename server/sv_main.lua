

local QBCore = exports['qb-core']:GetCoreObject()

RegisterServerEvent('guf1ck-beekeeping:installHive')
AddEventHandler('guf1ck-beekeeping:installHive', function(coords)
    local timestamp = os.time()
    exports.oxmysql:execute('INSERT INTO bees (coords, timestamp, beequeen) VALUES (@coords, @state, @bq)', {
        ['@coords'] = json.encode(coords),
        ['@state'] = timestamp,
        ['@bq'] = 0,
    }, function(rowschanged)
        if rowschanged then
            print(rowschanged.insertId)
            exports.oxmysql:execute('SELECT * FROM bees WHERE id = @id', {["@id"] = rowschanged.insertId}, function(hive)
                TriggerClientEvent('guf1ck-beekeeping:trigger_zone', -1, 2, hive[1])
            end)
        end
    end)
end)

QBCore.Functions.CreateCallback('guf1ck-beekeeping:removeHive', function(source, cb, pId)
    exports.oxmysql:execute('DELETE FROM bees WHERE id = @id', {["@id"] = pId})
    TriggerClientEvent('guf1ck-beekeeping:trigger_zone', -1, 4, pId)
    cb(true)
end)

QBCore.Functions.CreateCallback('guf1ck-beekeeping:addQueen', function(source, cb, key)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    local queenbee = xPlayer.Functions.GetItemByName("beequeen").amount
    if queenbee > 0 then
        exports.oxmysql:execute('UPDATE bees SET beequeen = (1 + @beequeen) WHERE id = @id', {["@id"] = key, ['@beequeen'] = math.random(1,1)}, function(rowschanged)
            exports.oxmysql:execute('SELECT * FROM bees WHERE id = @id', {["@id"] = key}, function(hive)
                cb(true)
                TriggerClientEvent('guf1ck-beekeeping:trigger_zone', -1, 3, hive[1])
            end)
        end)
    else
        cb(false)
    end
end)

QBCore.Functions.CreateCallback('guf1ck-beekeeping:getBeehives', function(source, cb)
    exports.oxmysql:execute('SELECT * FROM bees', {}, function(hives)
        cb(hives)
    end)
end)

QBCore.Functions.CreateUseableItem(HiveConfig.BeeHiveItem, function(source, item)
	local Player = QBCore.Functions.GetPlayer(source)
    TriggerClientEvent("guf1ck-beehives:setBeehives", source)
end)

RegisterServerEvent('beehive:removeItem')
AddEventHandler('beehive:removeItem', function(item , amount)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    xPlayer.Functions.RemoveItem(item , amount)
end)

RegisterServerEvent('beehive:addItem')
AddEventHandler('beehive:addItem', function(item , amount)
    local xPlayer = QBCore.Functions.GetPlayer(source)
    xPlayer.Functions.AddItem(item, amount)
end)

RegisterServerEvent('guf1ck-beekeeping:harvestHive')
AddEventHandler('guf1ck-beekeeping:harvestHive', function(pId, osururum)
    local src = source
    local xPlayer = QBCore.Functions.GetPlayer(source)
    exports.oxmysql:execute('DELETE FROM bees WHERE id = @id', {["@id"] = pId}, function(plants)
        TriggerClientEvent('guf1ck-beekeeping:trigger_zone', -1, 4, pId)
        if osururum > 0 then
            TriggerClientEvent('ananibikezsiktimkudurdu:ananinaminakorum', src)
        else
            TriggerClientEvent('ananibikezsiktimkudurdu:ananinaminakorumm', src)
        end
    end)
end)

