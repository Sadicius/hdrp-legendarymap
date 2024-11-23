local RSGCore = exports['rsg-core']:GetCoreObject()
local DBD = {}
local blipEntries = {}
local spawnedAnimals = {} -- Config.spawnedAnimals
local currentLegendaryAnimal = nil
lib.locale()

local function ClearSpawnedAnimals()
    for _, animalData in ipairs(spawnedAnimals) do
        if DoesEntityExist(animalData.ped) then
            DeleteEntity(animalData.ped)
        end
    end
    ClearGpsMultiRoute()
    currentLegendaryAnimal = nil
    DBD = {}
    spawnedAnimals = {}
    blipEntries = {}
end

local function getRandomAnimal()
    local keys = {}
    for key in pairs(Config.animalList) do
        table.insert(keys, key)
    end

    local randomIndex = math.random(1, #keys)
    local randomAnimalHash = keys[randomIndex]

    return randomAnimalHash
end

local function getAnimalModel(animalKey)
    local animalName = Config.animalList[animalKey]

    for _, modelData in ipairs(Config.animalModels) do
        for _, name in ipairs(modelData.names) do
            if name == animalName then
                return modelData.model, modelData.outfit
            end
        end
    end

    return nil, nil
end

local function LegendaryMap()
    local flowblockHash = -980176693
    local flowblockEnteringHash = -980176693
    local flowblock = UiflowblockRequest(flowblockHash)
    local statemachineHash = 978408792
    repeat Wait(0) until UiflowblockIsLoaded(flowblock) == 1
    UiflowblockEnter(flowblock, flowblockEnteringHash)
    if (UiStateMachineExists(statemachineHash) == 0) then
        UiStateMachineCreate(statemachineHash, flowblock)
    end

    if DBD and DBD.a then
        DatabindingRemoveDataEntry(DBD.a)
    end

    DBD = {}
    DBD.a = DatabindingAddDataContainerFromPath('', 'DynamicAnimalMap')

    for zoneIndex = 1, #Config.zones do
        local zoneKey = "Zone" .. zoneIndex
        local zoneStr = GetTextSubstring_2(zoneKey, GetLengthOfLiteralString(zoneKey))
        local zoneContainer = DatabindingAddDataContainer(DBD.a, zoneStr)
        DatabindingAddDataBool(zoneContainer, "isVisible", false) -- Marca como no visible
        DatabindingRemoveDataEntry(zoneContainer) -- Limpia la zona
        Wait(1)
    end

    local selectedZone = math.random(1, #Config.zones)
    local txt = 'Zone'..selectedZone
    local str = GetTextSubstring_2(txt, GetLengthOfLiteralString(txt))
    local animalHash = getRandomAnimal()

    DBD.b = DatabindingAddDataContainer(DBD.a, str)
    DBD.c = DatabindingAddDataHash(DBD.b, 'animalType', animalHash)
    DBD.d = DatabindingAddDataBool(DBD.b, 'isVisible', true)

    TaskItemInteraction(cache.ped, 17745825, 889797228, 1, 0, -1082130432)
    local animalModelKey, outfit = getAnimalModel(animalHash)  -- Get the model key and hash

    return selectedZone, animalModelKey, outfit
end

local function NearAnimal(model_entry, coords, outfit)
    -- spawn
    if Config.Debug then print(locale('cl_lang_1'), model_entry, coords) end
    local model = joaat(model_entry)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(10)
        RequestModel(model)
    end
    Wait(500)

    local spawnedAnimal = CreatePed(model, coords.x, coords.y, coords.z, true, true, true)
    Citizen.InvokeNative(0x77FF8D35EEC6BBC4, spawnedAnimal, outfit, 0)
    Citizen.InvokeNative(0x283978A15512B2FE, spawnedAnimal, true)
    Citizen.InvokeNative(0xDC19C288082E586E, spawnedAnimal, true, false)
    SetEntityAlpha(spawnedAnimal, 0, false)
    table.insert(spawnedAnimals, {ped = spawnedAnimal})
    if Config.Debug then print(locale('cl_lang_2'), coords) end
    -- if Config.FadeIn then
        for i = 0, 255, 51 do
            Wait(50)
            SetEntityAlpha(spawnedAnimal, i, false)
        end
    -- end

    return spawnedAnimal
end

local function GetGroundZ(x, y, z)
    local groundCheckHeight = 1000.0
    for i = 1, 10 do
        local foundGround, groundZ = GetGroundZFor_3dCoord(x, y, groundCheckHeight, false)
        if foundGround then
            return groundZ
        end
        groundCheckHeight = groundCheckHeight - 100.0
    end
    return z
end

local function SpawnLegendaryAnimal(animalHash, coords, outfit)
    if not coords then print(locale('cl_lang_3')) return end

    local searchRadius = 15 -- math.random(50, 80)
    local randomOffsetX = math.random(-searchRadius, searchRadius)
    local randomOffsetY = math.random(-searchRadius, searchRadius)

    local spawnCoords = {
        x = coords.x + randomOffsetX,
        y = coords.y + randomOffsetY,
        z = coords.z
    }
    local groundZ = GetGroundZ(spawnCoords.x, spawnCoords.y, spawnCoords.z) + 1.0  -- Adding 1.0 to ensure it spawns above ground

    local coord = vector3(spawnCoords.x, spawnCoords.y, groundZ)
    if Config.Debug then print(locale('cl_lang_1'), animalHash, coord, outfit) end
    local spawnedAnimal = NearAnimal(animalHash, coord, outfit)
    Wait(1000)
    if spawnedAnimal and DoesEntityExist(spawnedAnimal) then
        SetEntityAsNoLongerNeeded(spawnedAnimal)
        TaskWanderStandard(spawnedAnimal, 10.0, 10)
    else
        if Config.Debug then print(locale('cl_lang_4')) end
    end
end

local function createBlipAndGPS(zone, animalHash, outfit)
    local coords = Config.zones[zone].coords
    local blipText = Config.blip.blipText
    local gpsColor = Config.blip.gpsColor
    local proximityDistance = Config.blip.proximityDistance
    local timeout = Config.blip.timeout or 60000

    local blip = BlipAddForCoords(joaat('BLIP_STYLE_CREATOR_DEFAULT'), coords.x, coords.y, coords.z)
    SetBlipSprite(blip, joaat('blip_ambient_law'))
    BlipAddModifier(blip, joaat('BLIP_MODIFIER_AREA_PULSE'))
    SetBlipScale(blip, 0.8)
    SetBlipName(blip, blipText)
    blipEntries[#blipEntries + 1] = {coords = coords, handle = blip}

    if Config.blip.showgps == true then
        StartGpsMultiRoute(joaat(gpsColor), true, true)
        AddPointToGpsMultiRoute(coords.x, coords.y, coords.z)
        SetGpsMultiRouteRender(true)
    end

    CreateThread(function()    -- Bucle para verificar la distancia del jugador al área
        local startTime = GetGameTimer()
        while true do
            local playerCoords = GetEntityCoords(cache.ped)
            local distance = #(playerCoords - coords)
            local sleep = 1000
            if distance <= proximityDistance then
                if Config.blip.showgps == true then
                    ClearGpsMultiRoute()
                end
                for i = #blipEntries, 1, -1 do
                    local blipEntry = blipEntries[i]
                    RemoveBlip(blipEntry.handle)
                    table.remove(blipEntries, i)
                end
                lib.notify({ title = locale('cl_lang_5'), type = 'inform', duration = 5000 })
                TaskStartScenarioInPlace(cache.ped, `WORLD_HUMAN_CROUCH_INSPECT`, 0, true)
                Wait(5000)
                lib.notify({ title = locale('cl_lang_6'), description = locale('cl_lang_7'), type = 'inform', duration = 5000 })
                Wait(5000)
                ClearPedTasks(cache.ped)
                TriggerServerEvent('hdrp-legendaryanimal:server:spawnLegendaryAnimal', zone, animalHash, outfit)
                break
            end
            Wait(sleep)  -- Esperar antes de volver a comprobar
        end
    end)
end

RegisterNetEvent('hdrp-legendaryanimal:client:legendaryMap', function()
    ClearSpawnedAnimals()
    local selectedZone, animalModelKey, outfit = LegendaryMap()
    lib.notify({ title = locale('cl_lang_6'), description = locale('cl_lang_8')..' '..selectedZone, type = 'error', duration = 5000 })

    if Config.blip.bliplocation == true then
        createBlipAndGPS(selectedZone, animalModelKey, outfit)
    else
        TriggerServerEvent('hdrp-legendaryanimal:server:spawnLegendaryAnimal', selectedZone, animalModelKey, outfit)
    end
end)

RegisterNetEvent('hdrp-legendaryanimal:client:spawnLegendaryAnimal', function(zone, animalHash, outfit)
    if currentLegendaryAnimal and currentLegendaryAnimal.zone == zone then return end
    local coords = Config.zones[zone].coords
    SpawnLegendaryAnimal(animalHash, coords, outfit)
    currentLegendaryAnimal = {zone = zone, animalHash = animalHash}
end)

RegisterNetEvent('hdrp-legendaryanimal:client:removeLegendaryAnimal', function(zone)
    if currentLegendaryAnimal and currentLegendaryAnimal.zone == zone then
        ClearSpawnedAnimals()
        currentLegendaryAnimal = nil
    end
end)

-----------------------
-- START/STOP RESOURCE
-----------------------
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for _, v in ipairs(spawnedAnimals) do
        if DoesEntityExist(v.ped) then
            DeleteEntity(v.ped)
        end
    end
    if Config.blip.showgps == true then
        ClearGpsMultiRoute()
    end

    for i = #blipEntries, 1, -1 do
        local blipEntry = blipEntries[i]
        RemoveBlip(blipEntry.handle)
        blipEntries = {}
    end

    DBD = {}
    currentLegendaryAnimal = nil
end)