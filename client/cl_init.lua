

local QBCore = exports['qb-core']:GetCoreObject()

Citizen.CreateThread(function()
    for id, zone in ipairs(HiveZones) do
        exports["skyx-polyzone"]:AddCircleZone("guf1ck-beekeeping:bee_zone", zone[1], zone[2],{
            zoneEvents={"guf1ck-beekeeping:trigger_zone"},
            data = {
                id = id,
            },
        })
    end
end)


