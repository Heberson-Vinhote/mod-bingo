-- Armazena em cache o combustível dos veículos enquanto o servidor está rodando
local VehicleFuelCache = {}

-- Evento para quando o jogador entra no veículo: Busca do BD ou retorna cache
RegisterNetEvent('velocimetro:server:RequestFuel', function(plate)
    local src = source
    if not plate then return end

    plate = string.match(plate, "^%s*(.-)%s*$") -- Trim whitespace

    if VehicleFuelCache[plate] then
        -- Se já está em memória, manda direto pro cliente
        TriggerClientEvent('velocimetro:client:SyncFuel', src, plate, VehicleFuelCache[plate])
    else
        -- Se usa oxmysql e o script estiver startado, busca do BD
        if GetResourceState('oxmysql') == 'started' then
            exports.oxmysql:scalar('SELECT fuel_level FROM vehicle_fuel WHERE plate = ?', {plate}, function(fuel)
                if fuel then
                    VehicleFuelCache[plate] = fuel
                else
                    -- Se o veículo é novo, começa com MaxFuel
                    VehicleFuelCache[plate] = Config.MaxFuel
                    exports.oxmysql:insert('INSERT INTO vehicle_fuel (plate, fuel_level) VALUES (?, ?)', {plate, Config.MaxFuel})
                end
                TriggerClientEvent('velocimetro:client:SyncFuel', src, plate, VehicleFuelCache[plate])
            end)
        else
            -- Standalone mock sem DB
            VehicleFuelCache[plate] = Config.MaxFuel
            TriggerClientEvent('velocimetro:client:SyncFuel', src, plate, VehicleFuelCache[plate])
        end
    end
end)

-- Atualiza o nível de combustível vindo do cliente (ocorre quando sai do veículo)
RegisterNetEvent('velocimetro:server:UpdateFuel', function(plate, fuelLevel)
    if not plate or not fuelLevel then return end
    plate = string.match(plate, "^%s*(.-)%s*$")

    VehicleFuelCache[plate] = fuelLevel

    if GetResourceState('oxmysql') == 'started' then
        exports.oxmysql:execute('INSERT INTO vehicle_fuel (plate, fuel_level) VALUES (?, ?) ON DUPLICATE KEY UPDATE fuel_level = ?', {
            plate, fuelLevel, fuelLevel
        })
    end
end)

-- Sistema de Reabastecimento
-- Novo Sistema de Reabastecimento Parcial/Total
RegisterNetEvent('velocimetro:server:RefuelVehicleAmount', function(plate, requestedLiters)
    local src = source
    if not plate or type(requestedLiters) ~= "number" then return end
    plate = string.match(plate, "^%s*(.-)%s*$")

    local currentFuelServer = VehicleFuelCache[plate]

    if not currentFuelServer then
        if GetResourceState('oxmysql') == 'started' then
            exports.oxmysql:scalar('SELECT fuel_level FROM vehicle_fuel WHERE plate = ?', {plate}, function(fuel)
                if fuel then
                    ProcessRefuelAmount(src, plate, fuel, requestedLiters)
                else
                    TriggerClientEvent('velocimetro:client:Notify', src, "Veículo não registrado.")
                end
            end)
        else
            TriggerClientEvent('velocimetro:client:Notify', src, "Erro: Banco de dados inativo.")
        end
    else
        ProcessRefuelAmount(src, plate, currentFuelServer, requestedLiters)
    end
end)

function ProcessRefuelAmount(src, plate, currentFuelServer, requestedLiters)
    local fuelNeeded = Config.MaxFuel - currentFuelServer

    -- Validação de segurança para garantir que não compre mais do que cabe
    if requestedLiters > fuelNeeded then
        requestedLiters = math.floor(fuelNeeded)
    end

    if requestedLiters <= 0 then return end

    local cost = requestedLiters * Config.FuelPrice

    if Config.CobrarAbastecimento(src, cost) then
        local newFuelLevel = currentFuelServer + requestedLiters
        VehicleFuelCache[plate] = newFuelLevel

        if GetResourceState('oxmysql') == 'started' then
            exports.oxmysql:execute('UPDATE vehicle_fuel SET fuel_level = ? WHERE plate = ?', {newFuelLevel, plate})
        end

        TriggerClientEvent('velocimetro:client:SyncFuel', -1, plate, newFuelLevel)
        TriggerClientEvent('velocimetro:client:Notify', src, string.format("Você comprou %d litros por R$%d.", requestedLiters, cost))
    else
        TriggerClientEvent('velocimetro:client:Notify', src, "Dinheiro insuficiente para abastecer.")
    end
end
