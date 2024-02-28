local QBCore = exports[Config.CoreName]:GetCoreObject()

local nearDestination = false
local canDeliver = false
local destinationCoords = vector3(0, 0, 0)
local DestinationBlip = nil
local deliveryPromptShown = false
local deliveryPed = nil
local pedModel = "a_m_m_business_01"
local DelivermissionStarted = false
local Onmission = false
local Packagedelivered = false

function loadAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        RequestAnimDict(dict)
        Wait(500)
    end
end

function DrawText3D(coords, text)
    local onScreen, x, y = World3dToScreen2d(coords.x, coords.y, coords.z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextColour(255, 255, 255, 255)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextDropShadow()
        SetTextOutline()
        SetTextCentre(1)
        SetTextEntry("STRING")
        AddTextComponentString(text)
        DrawText(x, y)
    end
end

function spawnCar(modelName, x, y, z, heading)
    RequestModel(modelName)

    while not HasModelLoaded(modelName) do
        Wait(500)
    end

    local vehicle = CreateVehicle(modelName, x, y, z, heading, true, false)


    while not DoesEntityExist(vehicle) do
        Wait(500)
    end

    SetEntityHeading(vehicle, heading)

    TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)

    SetModelAsNoLongerNeeded(modelName)

    local vehiclePlate = GetVehicleNumberPlateText(vehicle)
    TriggerEvent("vehiclekeys:client:SetOwner", vehiclePlate, GetPlayerServerId(PlayerId()))
end

function spawnDeliveryPed(coords, heading)
    RequestModel(pedModel)

    while not HasModelLoaded(pedModel) do
        Wait(500)
    end

    local pedCoords = vector3(coords.x, coords.y, coords.z - 1.0)

    deliveryPed = CreatePed(4, pedModel, pedCoords.x, pedCoords.y, pedCoords.z, heading, false, false)
    SetEntityAsMissionEntity(deliveryPed, true, true)
    SetBlockingOfNonTemporaryEvents(deliveryPed, true)
    TaskStartScenarioInPlace(deliveryPed, "WORLD_HUMAN_AA_SMOKE", 0, false)

    FreezeEntityPosition(deliveryPed, true)
end

function Destinations()
    local pos = GetEntityCoords(PlayerPedId())

    if DestinationBlip then
        RemoveBlip(DestinationBlip)
    end

    local randomDestination = Config.Destinations[math.random(1, #Config.Destinations)]

    destinationCoords = vector3(randomDestination.x, randomDestination.y, randomDestination.z)
    local destinationHeading = randomDestination.h or 0.0

    DestinationBlip = AddBlipForCoord(destinationCoords.x, destinationCoords.y, destinationCoords.z)

    SetBlipSprite(DestinationBlip, 1)
    SetBlipDisplay(DestinationBlip, 2)
    SetBlipScale(DestinationBlip, 1.0)
    SetBlipAsShortRange(DestinationBlip, false)
    SetBlipColour(DestinationBlip, 27)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("Destination")
    EndTextCommandSetBlipName(DestinationBlip)
    SetBlipRoute(DestinationBlip, true)

    nearDestination = true
    deliveryPromptShown = false
    Onmission = true

    spawnDeliveryPed(destinationCoords, destinationHeading)
end

function Returncar()
    returncar = AddBlipForCoord(Config.DeliverCar[1].coords)

    SetBlipSprite(returncar, 1)
    SetBlipDisplay(returncar, 2)
    SetBlipScale(returncar, 1.0)
    SetBlipAsShortRange(returncar, false)
    SetBlipColour(returncar, 27)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("Destination")
    EndTextCommandSetBlipName(returncar)
    SetBlipRoute(returncar, true)
end    

function ResetDeliverMission()
    SetPedAsNoLongerNeeded(deliveryPed)
    DelivermissionStarted = false
    Onmission = false
    nearDestination = false
    canDeliver = false
    destinationCoords = vector3(0, 0, 0)
    deliveryPromptShown = false
    deliveryPed = nil

    if DestinationBlip then
        RemoveBlip(DestinationBlip)
    end
end

RegisterNetEvent("glx-weedrunss:client:DeleteCar")
AddEventHandler("glx-weedrunss:client:DeleteCar", function()
    if DelivermissionStarted and Onmission then
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        local correctVehicleModel = Config.DeliverCar[1].model

        if DoesEntityExist(vehicle) and GetEntityModel(vehicle) == GetHashKey(correctVehicleModel) then
            DeleteVehicle(vehicle)
            RemoveBlip(returncar)
            QBCore.Functions.Notify("Car Returned Successfully!")
            -- reward
            if Packagedelivered then
                QBCore.Functions.TriggerCallback('PackageDeliverReward', function(money)
                    QBCore.Functions.Notify('Good job $' .. money)
                end)
            else
                QBCore.Functions.Notify('Too bad u didnt finish the mission!', 'error')
                TriggerServerEvent("glx-weedruns:server:Packedweedremove")
            end      

            ResetDeliverMission()
        end

        Onmission = false
    end
end)

RegisterNetEvent("glx-weedrunss:client:startruns")
AddEventHandler("glx-weedrunss:client:startruns", function()
    if not DelivermissionStarted then
        loadAnimDict("timetable@jimmy@doorknock@")
        TaskPlayAnim(PlayerPedId(), "timetable@jimmy@doorknock@", "knockdoor_idle", 8.0, 1.0, -1, 1, 0, 0, 0, 0)
        QBCore.Functions.Progressbar("door", "knocking door..", 3000, false, true, {
            disableMovement = false,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        }, {}, {}, {}, function()
            QBCore.Functions.Notify("Take my car and deliver this package for me")
            TriggerServerEvent("glx-weedruns:server:Packedweedadd")
            DelivermissionStarted = true
        end, function()
            ClearPedTasks(PlayerPedId())
            QBCore.Functions.Notify("Canceled!", "error")
        end)
    else
        QBCore.Functions.Notify("Mission already started!", "error")
    end
end)

RegisterNetEvent("glx-weedrunss:client:Spawndelivercar")
AddEventHandler("glx-weedrunss:client:Spawndelivercar", function()
    if DelivermissionStarted then
        local model = Config.DeliverCar[1].model
        local x, y, z = Config.DeliverCar[1].coords
        local heading = Config.DeliverCar[1].heading

        Packagedelivered = false
        spawnCar(model, x, y, z, heading)
        Destinations()
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        local playerCoords = GetEntityCoords(PlayerPedId())
        local distanceToDestination = #(playerCoords - destinationCoords)

        if DelivermissionStarted and nearDestination and distanceToDestination < 1.50 and not deliveryPromptShown then
            DrawText3D(destinationCoords, "~g~ [E] ~w~ Deliver ")
            canDeliver = true
        else
            canDeliver = false
        end

        if IsControlJustReleased(0, 38) then
            local distance = #(playerCoords - destinationCoords)

            if DelivermissionStarted and nearDestination and canDeliver and distance < 1.50 then

                TaskTurnPedToFaceEntity(deliveryPed, PlayerPedId(), -1)
                TaskTurnPedToFaceEntity(PlayerPedId(), deliveryPed, -1)

                loadAnimDict('mp_common')
                TaskPlayAnim(PlayerPedId(), "mp_common", "givetake1_a", 8.0, 1.0, 1500, 1)

                loadAnimDict('mp_common')
                TaskPlayAnim(deliveryPed, "mp_common", "givetake1_a", 8.0, 1.0, 1500, 1)

                QBCore.Functions.Progressbar("deliver", "delivering...", 3000, false, true, {
                    disableMovement = false,
                    disableCarMovement = true,
                    disableMouse = false,
                    disableCombat = true,
                }, {}, {}, {}, function()
                    RemoveBlip(DestinationBlip)
                    SetPedAsNoLongerNeeded(deliveryPed)
                    QBCore.Functions.Notify("Thanks buddy! See you next time!")
                    TriggerServerEvent("glx-weedruns:server:Packedweedremove")
                    Packagedelivered = true
                    Returncar()
                end, function()
                    ClearPedTasks(PlayerPedId())
                    QBCore.Functions.Notify("Canceled!", "error")
                end)

                deliveryPromptShown = true
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        if DelivermissionStarted then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distanceToCar = #(playerCoords - vector3(Config.DeliverCar[1].coords.x, Config.DeliverCar[1].coords.y, Config.DeliverCar[1].coords.z))
            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false) 

            if not Onmission then
                if distanceToCar < 2.0 then
                    DrawMarker(27, Config.DeliverCar[1].coords.x, Config.DeliverCar[1].coords.y, Config.DeliverCar[1].coords.z - 0.65, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 255, 255, 255, 100, false, true, 2, nil, nil, false)  -- Change size to 1.0 and color to white
                    DrawText3D(vector3(Config.DeliverCar[1].coords.x, Config.DeliverCar[1].coords.y, Config.DeliverCar[1].coords.z), "~g~ [E] ~w~ Take the vehicle")

                    if IsControlJustReleased(0, 38) then
                        TriggerEvent("glx-weedrunss:client:Spawndelivercar")
                    end
                end
            elseif distanceToCar < 2.0 and DoesEntityExist(vehicle) and GetEntityModel(vehicle) == GetHashKey(Config.DeliverCar[1].model) then
                DrawMarker(27, Config.DeliverCar[1].coords.x, Config.DeliverCar[1].coords.y, Config.DeliverCar[1].coords.z - 0.65, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 255, 255, 255, 100, false, true, 2, nil, nil, false)  -- Change size to 1.0, color to white, and marker type to 23
                DrawText3D(vector3(Config.DeliverCar[1].coords.x, Config.DeliverCar[1].coords.y, Config.DeliverCar[1].coords.z), "~g~ [E] ~w~ Store the vehicle")

                if IsControlJustReleased(0, 38) then
                    TriggerEvent("glx-weedrunss:client:DeleteCar")
                end
            end
        end
    end
end)

--------

exports['qb-target']:AddBoxZone("knock door", vector3(843.99, -902.9, 25.25), 1, 1, {
	name = "dearch",
	heading = 345,
	--debugPoly = Config.PolyZone,
	minZ = 24.25,
    maxZ = 27.25,
}, {
	options = {
		{
            type = 'client',
            event = 'glx-weedrunss:client:startruns',
            icon = 'fas fa-briefcase',
            label = 'knock ...',
		},
	},
	distance = 2.5
})