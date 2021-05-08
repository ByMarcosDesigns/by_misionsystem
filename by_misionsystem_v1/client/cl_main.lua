ESX = nil
local display = false
local MisionsOn = true 
local STATE_NONE = 0
local RECORDING_POINTS = 1
local Misions = {}
local coords = {}
local GoToCollect = false 
local IsLooted = false 
local TrailerSpawned = false

local Status = {
    state = STATE_NONE,
    index = 0,
    checkpoint = 0
}

local recordedCheckpoints = {}


Citizen.CreateThread(function()
    while ESX == nil do
	    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
	    Citizen.Wait(0)
    end
byLoadNpcs()
end)

RegisterNUICallback("exit", function(data)
    chat("exited", {0,255,0})
    SetDisplay(false)
end)

RegisterNUICallback("main", function(data)
    name = data.text
    bytype = data.text2 
    saveMision(name, bytype)
    SetDisplay(false)
end)

RegisterNUICallback("error", function(data)
    chat(data.error, {255,0,0})
    SetDisplay(false)
end)

RegisterNUICallback("create", function()
    enableRecording()
    SetDisplay(false)
end)

RegisterNetEvent('by:OpenNui')
AddEventHandler('by:OpenNui', function(group)
    print(group)
    if group == 'admin' then
        print('hola')
        SetDisplay(true)
    else 
        ESX.ShowNotification('Lo siento amigo pero parece que no tienes permisos')
    end
end)

function enableRecording()
    SetWaypointOff()
    Status.state = RECORDING_POINTS
    ESX.ShowNotification("Abre el mapa y selecciona la nueva ruta")
end

function saveMision(name, bytype)
    TriggerServerEvent('by_missionsystem:savemission_sv', name, bytype, recordedCheckpoints)
    ESX.ShowNotification("La mision " .. name .. " ha sido guardada")
    cleanupRecording()
    Status.state = STATE_NONE 
end

function SetDisplay(bool)
    display = bool
    SetNuiFocus(bool, bool)
    SendNUIMessage({
        type = "ui",
        status = bool,
    })
end

Citizen.CreateThread(function()
    while display do
        Citizen.Wait(0)

        DisableControlAction(0, 1, display)
        DisableControlAction(0, 2, display)
        DisableControlAction(0, 142, display)
        DisableControlAction(0, 18, display)
        DisableControlAction(0, 322, display)
        DisableControlAction(0, 106, display)
    end
end)

function chat(str, color)
    TriggerEvent(
        'chat:addMessage',
        {
            color = color,
            multiline = true,
            args = {str}
        }
    )
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(100)
        
        if Status.state == RECORDING_POINTS then
            if IsWaypointActive() then
                local waypointCoords = GetBlipInfoIdCoord(GetFirstBlipInfoId(8))
                local retval, coords = GetClosestVehicleNode(waypointCoords.x, waypointCoords.y, waypointCoords.z, 1)
                SetWaypointOff()

                for index, checkpoint in pairs(recordedCheckpoints) do
                    if GetDistanceBetweenCoords(coords.x, coords.y, coords.z, checkpoint.coords.x, checkpoint.coords.y, checkpoint.coords.z, false) < 1.0 then
                        RemoveBlip(checkpoint.blip)
                        table.remove(recordedCheckpoints, index)
                        coords = nil

                        for i = index, #recordedCheckpoints do  
                            ShowNumberOnBlip(recordedCheckpoints[i].blip, i)
                        end
                        break
                    end
                end

                if (coords ~= nil) then
                    local number = 0
                    if #recordedCheckpoints <= number then
                        local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
                        SetBlipColour(blip, Config.Blips.checkpointBlipColor)
                        SetBlipAsShortRange(blip, true)

                        table.insert(recordedCheckpoints, {blip = blip, coords = coords})
                        print(#recordedCheckpoints+1, coords.x, coords.y, coords.z)
                    end
                end
            end
        else
            cleanupRecording()
        end
    end
end)


function cleanupRecording()
    for _, checkpoint in pairs(recordedCheckpoints) do
        RemoveBlip(checkpoint.blip)
        checkpoint.blip = nil
    end
    recordedCheckpoints = {}
end

function LoadMision(name, alonename)
    ESX.TriggerServerCallback("by_missionsystem:getcoords", function(result, name)
        for i = 1, #result, 1 do 
            local goname = result[i]['name']
            if goname == byname then
                coords = vector3(result[i]['coords']['x'], result[i]['coords']['y'], result[i]['coords']['z'])
                --print(alonename)
                BlipGo(coords)
                pointsLoot(coords, alonename)
                spawnCarIn(alonename)
            end
        end 
    end, name)
end

function BlipGo(coords)
    finishGo2()

    blip2 = AddBlipForCoord(coords.x, coords.y, coords.z)

    SetBlipRoute(blip2, true)
    AddTextComponentString('Mision - 1')
	BeginTextCommandSetBlipName("STRING")
	EndTextCommandSetBlipName(blip2) 
end

function BlipBack(alonename)
    finishGo2()
    local coords = Config.Coords
    if alonename == "camionero" then 
        blip2 = AddBlipForCoord(coords.EntregaCamionero.x, coords.EntregaCamionero.y, coords.EntregaCamionero.z)
    elseif alonename == "piloto" then 
        blip2 = AddBlipForCoord(coords.EntregaPiloto.x, coords.EntregaPiloto.y, coords.EntregaPiloto.z)
    elseif alonename == "maritimo" then 
        blip2 = AddBlipForCoord(coords.EntregaMaritimo.x, coords.EntregaMaritimo.y, coords.EntregaMaritimo.z)
    end

    SetBlipRoute(blip2, true)
    AddTextComponentString('Mision - 1')
	BeginTextCommandSetBlipName("STRING")
	EndTextCommandSetBlipName(blip2) 
end

function finishGo2()
    RemoveBlip(blip2)
end

function MenuLoad(alonename)
    --print(alonename)
    ESX.TriggerServerCallback("by_missionsystem:getname", function(result, cb,  alonename)
        local elements = {}
        for i = 1, #result, 1 do
            table.insert(elements, {
                label = result[i]['name'],
                value = result[i]['name'],
                bytype = result[i]['bytype']
            })
        end

        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'getname', {
            title = ('ByMissions System'),
            align = 'right', 
            elements = elements
        }, function (data, menu)

            byname = data.current.value
            alonename = data.current.bytype
            --print(alonename)
            GoToCollect = true
            LoadMision(byname, alonename)
            ESX.ShowNotification('Ves a buscar los suministros de la mision ' .. data.current.value .. ' y traelas de vuelta soldado.')
            menu.close()
        end)
    end, alonename)
end

function pointsLoot(coords, alonename)
    print(coords)
    print(alonename)
    Citizen.CreateThread(function()
        while true do 
            Citizen.Wait(0)
            local pointCoords = vector3(coords.x, coords.y, coords.z)

            if GoToCollect == true and IsLooted == false  then
                local player = PlayerPedId()
                local getcoords = GetEntityCoords(player, false)
                DrawMarker(1, pointCoords.x, pointCoords.y, pointCoords.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 30.5, 30.5, 0.5, 255, 41, 41, 100, false, true, 2, false, false, false, false)

                if alonename == "camionero" then
                    if Vdist2(getcoords, pointCoords) < 30.0 then 
                        DrawText3D(pointCoords.x, pointCoords.y - 3.0, pointCoords.z + 0.8, "Presiona ~b~E ~w~para enganchar el remolque")

                        if IsControlJustPressed(1, 51) then 
                            finishGo2()
                            IsLooted = true
                            BlipBack(alonename)
                            return
                            endMisionA(alonename)
                        end 
                    end 
                    if Vdist2(getcoords, pointCoords) < 100.0 then 
                        if TrailerSpawned == false then
                            spawnCarOu(pointCoords)
                            TrailerSpawned = true
                        end 
                    end 
                elseif alonename == "piloto" then 
                    if Vdist2(getcoords, pointCoords) < 30.0 then 
                        DrawText3D(pointCoords.x, pointCoords.y - 3.0, pointCoords.z + 0.8, "Presiona ~b~E ~w~para subir los suministros al avion")

                        if IsControlJustPressed(1, 51) then 
                            finishGo2()
                            IsLooted = true
                            BlipBack(alonename)
                            endMisionA(alonename)
                            return
                        end 
                    end 
                elseif alonename == "maritimo" then 
                    if Vdist2(getcoords, pointCoords) < 30.0 then 
                        DrawText3D(pointCoords.x, pointCoords.y - 3.0, pointCoords.z + 0.8, "Presiona ~b~E ~w~para subir los suministros a la lancha")

                        if IsControlJustPressed(1, 51) then 
                            finishGo2()
                            IsLooted = true
                            BlipBack(alonename)
                            endMisionA(alonename)
                            return
                        end 
                    end 
                end
            end
        end
    end)
end

function endMisionA(alonename)
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)
            local config = Config.Coords
            local player = PlayerPedId()
            local getcoords = GetEntityCoords(player, false)
           -- print(alonename)

            if GoToCollect == true and IsLooted == true then
                if alonename == "camionero" then 
                    local coords = vector3(config.EntregaCamionero.x, config.EntregaCamionero.y, config.EntregaCamionero.z)
                    if Vdist2(getcoords, coords) < 50.0 then 
                        DrawMarker(1, config.EntregaCamionero.x, config.EntregaCamionero.y, config.EntregaCamionero.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 30.5, 30.5, 0.5, 255, 41, 41, 100, false, true, 2, false, false, false, false)
                        DrawText3D(config.EntregaCamionero.x, config.EntregaCamionero.y, config.EntregaCamionero.z + 0.8, "Pressiona ~b~E ~w~para entregar el remolque")

                        if IsControlJustPressed(1, 51) then 
                            finishGo2()
                            carDeleter()
                            print(alonename)
                            TriggerServerEvent('by_missionsystem:rewardCam', source)
                            IsLooted = false 
                            return
                        end 
                    end 
                elseif alonename == "piloto" then 
                    local coords = vector3(config.EntregaPiloto.x, config.EntregaPiloto.y, config.EntregaPiloto.z)
                    if Vdist2(getcoords, coords) < 50.0 then 
                        DrawMarker(1, config.EntregaPiloto.x, config.EntregaPiloto.y, config.EntregaPiloto.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 30.5, 30.5, 0.5, 255, 41, 41, 100, false, true, 2, false, false, false, false)
                        DrawText3D(config.EntregaPiloto.x, config.EntregaPiloto.y, config.EntregaPiloto.z + 0.8, "Pressiona ~b~E ~w~para entregar el remolque")

                        if IsControlJustPressed(1, 51) then 
                            finishGo2()
                            carDeleter()
                            print(alonename)
                            TriggerServerEvent('by_missionsystem:rewardPil', source)
                            IsLooted = false 
                            return
                        end 
                    end 
                elseif alonename == "maritimo" then 
                    local coords = vector3(config.EntregaMaritimo.x, config.EntregaMaritimo.y, config.EntregaMaritimo.z)
                    if Vdist2(getcoords, coords) < 50.0 then 
                        DrawMarker(1, config.EntregaMaritimo.x, config.EntregaMaritimo.y, config.EntregaMaritimo.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 30.5, 30.5, 0.5, 255, 41, 41, 100, false, true, 2, false, false, false, false)
                        DrawText3D(config.EntregaMaritimo.x, config.EntregaMaritimo.y, config.EntregaMaritimo.z + 0.8, "Pressiona ~b~E ~w~para entregar el remolque")

                        if IsControlJustPressed(1, 51) then 
                            finishGo2()
                            carDeleter()
                            print(alonename)
                            TriggerServerEvent('by_missionsystem:rewardMar', source)
                            IsLooted = false 
                            return
                        end 
                    end 
                end
            end 
        end
    end)
end 

function spawnCarIn(byname)
    local player = PlayerPedId()
    coords = Config.Coords
    --print(byname)

    if byname == "camionero" then
        ESX.Game.SpawnVehicle("phantom", coords.EntregaCamionero, 270, function(vehicle)
            TaskWarpPedIntoVehicle(player, vehicle, -1)
        end)
    elseif byname == "piloto" then 
        ESX.Game.SpawnVehicle("vestra", coords.EntregaPiloto, 270, function(vehicle)
            TaskWarpPedIntoVehicle(player, vehicle, -1)
        end)
    elseif byname == "maritimo" then
        ESX.Game.SpawnVehicle("dinghy4", coords.EntregaMaritimo, 270, function(vehicle)
            TaskWarpPedIntoVehicle(player, vehicle, -1)
        end)
    end
end

function spawnCarOu(coords)
    coords = vector3(coords.x, coords.y, coords.z)
    local player = PlayerPedId()

    ESX.Game.SpawnVehicle("trailers2", coords, 270, function(vehicle)
    end)
end

function carDeleter()
    local player = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(player, true)

    ESX.Game.DeleteVehicle(vehicle)
end

function byLoadNpcs()
    ESX.TriggerServerCallback('by_missionsystem:getpeds', function(result, coords)
        for i = 1, #result, 1 do 
            local alonename = result[i]['bytype']
            local coords = vector3(result[i]['coords']['x'], result[i]['coords']['y'], result[i]['coords']['z'])

            SpawnPeds(coords)

            IsPedSpawned(coords, alonename)
        end 
    end)
end

function SpawnPeds(coords)
    local hashped = Config.Ped.Hash
    local hash = GetHashKey(hashped)
    local pedCoords = vector3(coords.x, coords.y, coords.z)
    ped = CreatePed("PED_TYPE_CIVFEMALE", hashped, pedCoords.x, pedCoords.y, pedCoords.z - 1.0, 100.220, false, true)

    while not HasModelLoaded(hash) do
        RequestModel(hash)
        Wait(20)
    end

    
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    blipped = AddBlipForCoord(pedCoords.x, pedCoords.y, pedCoords.z)

    SetBlipSprite (blipped, 161)
    SetBlipDisplay(blipped, 4)
    SetBlipScale  (blipped, 1.2)
    SetBlipColour (blipped, 1)
    SetBlipAsShortRange(blip, true)

    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Misiones')
    EndTextCommandSetBlipName(blipped)
end

function IsPedSpawned(coords, alonename)
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)
            local pedCoords = vector3(coords.x, coords.y, coords.z)
            local text = vector3(coords.x, coords.y, coords.z)
            local player = PlayerPedId()
            local getcoords = GetEntityCoords(player, false)
            local alonename = alonename

            if MisionsOn == true then 
                if Vdist2(getcoords, text) < 5.5 then
                    DrawText3D(pedCoords.x, pedCoords.y, pedCoords.z + 0.95, "Presiona ~y~E ~w~para mirar las misiones")
                    if IsControlJustPressed(1,51) then 
                        --print(alonename)
                        MenuLoad(alonename)
                        TrailerSpawned = false
                    end
                end 
            end 
        end
    end)
end 

function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x,y,z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end
