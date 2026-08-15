local inVehicle = false
local currentVehicle = nil
local vehiclePlate = nil
local currentFuel = Config.MaxFuel
local uiVisible = false

RegisterNetEvent('velocimetro:client:Notify', function(msg)
    -- TODO: Modifique para o sistema de notificação do seu framework (ex: QBCore.Functions.Notify)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(msg)
    DrawNotification(false, false)
end)

-- Sincroniza o combustível recebido do servidor
RegisterNetEvent('velocimetro:client:SyncFuel', function(plate, fuel)
    if vehiclePlate == plate then
        currentFuel = fuel
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
<<<<<<< Updated upstream

=======

>>>>>>> Stashed changes
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
<<<<<<< Updated upstream

        if IsPedInAnyVehicle(ped, false) then
            sleep = 50

            local veh = GetVehiclePedIsIn(ped, false)

=======

        if IsPedInAnyVehicle(ped, false) then
            sleep = 50

            local veh = GetVehiclePedIsIn(ped, false)

>>>>>>> Stashed changes
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
<<<<<<< Updated upstream

=======

>>>>>>> Stashed changes
            -- Se for o motorista, processa a UI e o gasto de combustivel
            if GetPedInVehicleSeat(veh, -1) == ped then
                -- Informações do Veículo
                local speed = GetEntitySpeed(veh) * 3.6 -- Converte m/s para KM/h
                local rpm = GetVehicleCurrentRpm(veh)
                local class = GetVehicleClass(veh)
                local isBicycle = (class == 13)
                local gear = GetGearString(veh, isBicycle)
                local engineHealth = GetVehicleEngineHealth(veh)
<<<<<<< Updated upstream

=======

>>>>>>> Stashed changes
                -- Luzes
                local _, lightsOn, highbeams = GetVehicleLightsState(veh)
                local lightStatus = false
                if lightsOn == 1 or highbeams == 1 then lightStatus = true end
<<<<<<< Updated upstream

=======

>>>>>>> Stashed changes
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
<<<<<<< Updated upstream

=======

>>>>>>> Stashed changes
                -- Consumo de combustível
                if not isBicycle and GetIsVehicleEngineRunning(veh) then
                    local usageRate = Config.ClassFuelUsage[class] or Config.DefaultFuelUsage
                    -- Gasta baseado no RPM e multiplicador. Só gasta se RPM for razoável ou o carro estiver andando.
                    if rpm > 0.2 then
                        local fuelDrop = (rpm * usageRate * Config.FuelConsumptionMultiplier) / 100
                        currentFuel = currentFuel - fuelDrop
                        if currentFuel < 0.0 then currentFuel = 0.0 end
<<<<<<< Updated upstream

=======

>>>>>>> Stashed changes
                        -- Desliga o motor se acabar a gasolina
                        if currentFuel <= 0.0 then
                            SetVehicleEngineOn(veh, false, true, true)
                        end
                    end
                end
            else
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
<<<<<<< Updated upstream

=======

>>>>>>> Stashed changes
                -- Salva no DB ao sair apenas se era o motorista (quem gasta o combustível)
                if currentVehicle and vehiclePlate and GetPedInVehicleSeat(currentVehicle, -1) == ped then
                    TriggerServerEvent('velocimetro:server:UpdateFuel', vehiclePlate, currentFuel)
                end
<<<<<<< Updated upstream

=======

>>>>>>> Stashed changes
                currentVehicle = nil
                vehiclePlate = nil
            end
        end

        Wait(sleep)
    end
end)

-- Comando para reabastecer
RegisterCommand(Config.RefuelCommand, function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
<<<<<<< Updated upstream

=======

>>>>>>> Stashed changes
    if veh == 0 then
        -- Tenta pegar o veiculo mais proximo se estiver a pe
        veh = GetClosestVehicle(GetEntityCoords(ped), 3.0, 0, 71)
    end
<<<<<<< Updated upstream

    if veh ~= 0 then
        local pCoords = GetEntityCoords(ped)
        local isNearStation = false

=======

    if veh ~= 0 then
        local pCoords = GetEntityCoords(ped)
        local isNearStation = false

>>>>>>> Stashed changes
        for _, stationCoords in ipairs(Config.GasStations) do
            if #(pCoords - stationCoords) <= Config.RefuelDistance then
                isNearStation = true
                break
            end
        end
<<<<<<< Updated upstream

=======

>>>>>>> Stashed changes
        if isNearStation then
            local plate = GetVehicleNumberPlateText(veh)
            if plate then
                plate = string.match(plate, "^%s*(.-)%s*$")
                TriggerServerEvent('velocimetro:server:RefuelVehicle', plate)
            end
        else
            TriggerEvent('velocimetro:client:Notify', "Você não está próximo a um posto de gasolina.")
        end
    else
        TriggerEvent('velocimetro:client:Notify', "Nenhum veículo próximo para abastecer.")
    end
end)
