local inVehicle = false
local currentVehicle = nil
local vehiclePlate = nil
local currentFuel = Config.MaxFuel
local uiVisible = false
local wasDriver = false

RegisterNetEvent('velocimetro:client:Notify', function(msg)
    -- TODO: Modifique para o sistema de notificação do seu framework (ex: QBCore.Functions.Notify)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(msg)
    DrawNotification(false, false)
end)

-- Sincroniza o combustível recebido do servidor
RegisterNetEvent('velocimetro:client:SyncFuel', function(plate, fuel)
    if vehiclePlate == plate and currentVehicle then
        currentFuel = fuel
        SetVehicleFuelLevel(currentVehicle, currentFuel)
    end
end)

-- Mostra/Esconde a UI
local function ToggleUI(state)
    if uiVisible == state then return end
    uiVisible = state
    SendNUIMessage({
        action = "toggle",
        show = state
    })
end

-- Calcula a marcha correta
local function GetGearString(veh, isBicycle)
    if isBicycle then return "-" end
    local gear = GetVehicleCurrentGear(veh)
    local speed = GetEntitySpeed(veh)

    if speed == 0 and gear == 0 then
        return "N"
    elseif gear == 0 and speed > 0 then
        return "R"
    else
        return tostring(gear)
    end
end

-- Loop Principal de Detecção e Atualização
CreateThread(function()
    while true do
        local sleep = 500
        local ped = PlayerPedId()

        if IsPedInAnyVehicle(ped, false) and not IsPedInAnyHeli(ped) and not IsPedInAnyPlane(ped) then
             -- Opcional: Se quiser que mostre em heli/avião remova as verificações acima,
             -- mas o prompt pediu que funcione em tudo, então vamos apenas checar IsPedInAnyVehicle
        end

        if IsPedInAnyVehicle(ped, false) then
            sleep = 50

            local veh = GetVehiclePedIsIn(ped, false)

            -- Lógica de entrada no veículo
            if veh ~= currentVehicle then
                currentVehicle = veh
                vehiclePlate = GetVehicleNumberPlateText(veh)
                if vehiclePlate then
                    vehiclePlate = string.match(vehiclePlate, "^%s*(.-)%s*$")
                    -- Solicita o combustível pro server
                    TriggerServerEvent('velocimetro:server:RequestFuel', vehiclePlate)
                end
                inVehicle = true
                ToggleUI(true)
            end

            -- Se for o motorista, processa a UI e o gasto de combustivel
            if GetPedInVehicleSeat(veh, -1) == ped then
                wasDriver = true
                -- Informações do Veículo
                local speed = GetEntitySpeed(veh) * 3.6 -- Converte m/s para KM/h
                local rpm = GetVehicleCurrentRpm(veh)
                local class = GetVehicleClass(veh)
                local isBicycle = (class == 13)
                local gear = GetGearString(veh, isBicycle)
                local engineHealth = GetVehicleEngineHealth(veh)

                -- Luzes
                local _, lightsOn, highbeams = GetVehicleLightsState(veh)
                local lightStatus = false
                if lightsOn == 1 or highbeams == 1 then lightStatus = true end

                -- Portas (simplificado: se alguma porta estiver aberta)
                local doorsOpen = false
                for i=0, 5 do
                    if GetVehicleDoorAngleRatio(veh, i) > 0.0 then
                        doorsOpen = true
                        break
                    end
                end

                -- Motor (status visual se o carro ta quebrado)
                local engineBad = engineHealth < 400.0

                -- Atualiza a UI
                SendNUIMessage({
                    action = "update",
                    speed = math.floor(speed),
                    gear = gear,
                    fuel = currentFuel,
                    maxFuel = Config.MaxFuel,
                    lights = lightStatus,
                    doors = doorsOpen,
                    engine = engineBad,
                    isBicycle = isBicycle
                })

                -- Consumo de combustível
                if not isBicycle and GetIsVehicleEngineRunning(veh) then
                    local usageRate = Config.ClassFuelUsage[class] or Config.DefaultFuelUsage
                    -- Gasta baseado no RPM e multiplicador. Só gasta se RPM for razoável ou o carro estiver andando.
                    if rpm > 0.2 then
                        local fuelDrop = (rpm * usageRate * Config.FuelConsumptionMultiplier) / 100
                        currentFuel = currentFuel - fuelDrop
                        if currentFuel < 0.0 then currentFuel = 0.0 end

                        SetVehicleFuelLevel(veh, currentFuel)

                        -- Desliga o motor se acabar a gasolina
                        if currentFuel <= 0.0 then
                            SetVehicleEngineOn(veh, false, true, true)
                        end
                    end
                end
            else
                wasDriver = false
                -- Passageiro só vê a UI
                local speed = GetEntitySpeed(veh) * 3.6
                SendNUIMessage({
                    action = "update",
                    speed = math.floor(speed),
                    gear = "-",
                    fuel = currentFuel,
                    maxFuel = Config.MaxFuel,
                    lights = false,
                    doors = false,
                    engine = false,
                    isBicycle = false
                })
            end

        else
            -- Saiu do veículo
            if inVehicle then
                inVehicle = false
                ToggleUI(false)

                -- Salva no DB ao sair apenas se era o motorista (quem gasta o combustível)
                if currentVehicle and vehiclePlate and wasDriver then
                    TriggerServerEvent('velocimetro:server:UpdateFuel', vehiclePlate, currentFuel)
                end

                currentVehicle = nil
                vehiclePlate = nil
                wasDriver = false
            end
        end

        Wait(sleep)
    end
end)

-- Criação de Blips no Mapa
CreateThread(function()
    if Config.EnableBlips then
        for _, coords in ipairs(Config.GasStations) do
            local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
            SetBlipSprite(blip, Config.BlipSprite)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, Config.BlipScale)
            SetBlipColour(blip, Config.BlipColour)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(Config.BlipName)
            EndTextCommandSetBlipName(blip)
        end
    end
end)

local isRefuelMenuOpen = false

-- Lógica dos marcadores nos postos de gasolina
CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local pCoords = GetEntityCoords(ped)

        if not isRefuelMenuOpen then
            for _, stationCoords in ipairs(Config.GasStations) do
                local dist = #(pCoords - stationCoords)

                if dist < 15.0 then
                    sleep = 0
                    -- Draw Marker on the ground
                    DrawMarker(1, stationCoords.x, stationCoords.y, stationCoords.z - 1.0,
                               0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                               Config.RefuelDistance, Config.RefuelDistance, 0.5,
                               255, 165, 0, 100, false, true, 2, false, nil, nil, false)

                    if dist <= Config.RefuelDistance then
                        -- Display Text
                        SetTextComponentFormat("STRING")
                        AddTextComponentString("Pressione ~y~[E]~s~ para reabastecer")
                        DisplayHelpTextFromStringLabel(0, 0, 1, -1)

                        if IsControlJustPressed(0, Config.InteractKey) then
                            local veh = GetVehiclePedIsIn(ped, false)

                            -- Se o jogador está a pé, tenta achar o veículo mais próximo
                            if veh == 0 then
                                veh = GetClosestVehicle(pCoords.x, pCoords.y, pCoords.z, Config.RefuelDistance, 0, 71)
                            end

                            if veh ~= 0 then
                                -- Força atualização do combustível no servidor antes de tentar abastecer
                                -- Isto previne o desync quando o motorista tenta abastecer dentro do veículo
                                if currentVehicle == veh and wasDriver then
                                    TriggerServerEvent('velocimetro:server:UpdateFuel', vehiclePlate, currentFuel)
                                end

                                local plate = GetVehicleNumberPlateText(veh)
                                if plate then
                                    plate = string.match(plate, "^%s*(.-)%s*$")
                                    local vehicleCurrentFuel = currentFuel
                                    if currentVehicle ~= veh then
                                        -- Se tentou abastecer outro carro que não está usando, pega a gasolina da entity
                                        vehicleCurrentFuel = GetVehicleFuelLevel(veh)
                                    end

                                    local missingFuel = Config.MaxFuel - vehicleCurrentFuel

                                    if missingFuel > 1.0 then
                                        isRefuelMenuOpen = true
                                        SetNuiFocus(true, true)
                                        SendNUIMessage({
                                            action = "openRefuel",
                                            missingFuel = missingFuel,
                                            pricePerLiter = Config.FuelPrice,
                                            plate = plate
                                        })
                                    else
                                        TriggerEvent('velocimetro:client:Notify', "O tanque já está cheio!")
                                    end
                                end
                            else
                                TriggerEvent('velocimetro:client:Notify', "Nenhum veículo próximo para abastecer.")
                            end
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

-- NUI Callbacks para Reabastecimento
RegisterNUICallback('closeRefuel', function(data, cb)
    isRefuelMenuOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('confirmRefuel', function(data, cb)
    isRefuelMenuOpen = false
    SetNuiFocus(false, false)
    TriggerServerEvent('velocimetro:server:RefuelVehicleAmount', data.plate, data.liters)
    cb('ok')
end)
