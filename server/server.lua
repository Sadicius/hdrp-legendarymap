local RSGCore = exports['rsg-core']:GetCoreObject()
local spawnedAnimals = {} -- Config.spawnedAnimals  -- Para controlar qué animales están spawneados
lib.locale()

-----------------------
-- use campfire
-----------------------
RSGCore.Functions.CreateUseableItem('legendarymap', function(source, item)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    TriggerClientEvent('hdrp-legendaryanimal:client:legendaryMap', src)
    Player.Functions.RemoveItem('legendarymap', 1)
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items['legendarymap'], 'remove', 1)
end)

local function isPlayerInZone(zone)
    for _, player in ipairs(GetPlayers()) do
        local ped = GetPlayerPed(player)
        local playerCoords = GetEntityCoords(ped)
        local distance = #(playerCoords - zone.coords)
        if distance <= Config.proximityDistance then
            return true
        end
    end
    return false
end

RegisterNetEvent('hdrp-legendaryanimal:server:checkZone', function(zone)
    if not isPlayerInZone(zone) then
        TriggerClientEvent('hdrp-legendaryanimal:client:removeLegendaryAnimal', -1, zone)  -- Eliminar animal y blip si nadie está en la zona
        spawnedAnimals[zone] = nil
    end
end)

local function isValidZone(zone)
    return Config.zones[zone] ~= nil
end

local function addSpawnedAnimal(zone, animalHash)
    if not spawnedAnimals[zone] then
        spawnedAnimals[zone] = {}  -- Inicializar la entrada para la zona
    end
    spawnedAnimals[zone].animalHash = animalHash
end

RegisterNetEvent('hdrp-legendaryanimal:server:spawnLegendaryAnimal', function(zone, animalHash, outfit)
    if isValidZone(zone) then    -- Procesar el spawn del animal
        if spawnedAnimals[zone] then return end    -- Si ya hay un animal en esta zona, no hacer nada
        spawnedAnimals[zone] = { animalHash = animalHash, outfit = outfit }    -- Marcar que hay un animal spawneado en esa zona
        addSpawnedAnimal(zone, animalHash)  -- Agregar el animal a la tabla
        TriggerClientEvent('hdrp-legendaryanimal:client:spawnLegendaryAnimal', -1, zone, animalHash, outfit)    -- Enviar el evento a todos los clientes para que spawneen el animal
    else
        if Config.Debug then print(locale('sv_lang_1')..": " .. zone, animalHash, outfit) end
    end
end)

RegisterNetEvent('hdrp-legendaryanimal:server:removeLegendaryAnimal', function(zone)
    spawnedAnimals[zone] = nil  -- Marcar que el animal ha sido eliminado
    TriggerClientEvent('hdrp-legendaryanimal:client:removeLegendaryAnimal', -1, zone)    -- Notificar a todos los clientes que el animal ha sido eliminado
end)

AddEventHandler('playerJoining', function()
    local src = source
    for zone, _ in pairs(spawnedAnimals) do
        -- Notificar al jugador que hay un animal spawneado en esta zona
        -- TriggerClientEvent('hdrp-legendaryanimal:client:spawnLegendaryAnimal', src, zone, getRandomAnimal())
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    for zone, _ in pairs(spawnedAnimals) do
        if not isPlayerInZone(zone) then
            spawnedAnimals[zone] = nil
            TriggerClientEvent('hdrp-legendaryanimal:client:removeLegendaryAnimal', -1, zone)
        end
    end
end)
