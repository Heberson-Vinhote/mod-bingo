-- Armazena em cache o combustível dos veículos enquanto o servidor está rodando
local VehicleFuelCache = {}

-- Evento para quando o jogador entra no veículo: Busca do BD ou retorna cache
RegisterNetEvent('velocimetro:server:RequestFuel', function(plate)
    local src = source
    if not plate then return end
<<<<<<< Updated upstream

=======

>>>>>>> Stashed changes
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
<<<<<<< Updated upstream

=======

>>>>>>> Stashed changes
    VehicleFuelCache[plate] = fuelLevel

    if GetResourceState('oxmysql') == 'started' then
        exports.oxmysql:execute('INSERT INTO vehicle_fuel (plate, fuel_level) VALUES (?, ?) ON DUPLICATE KEY UPDATE fuel_level = ?', {
            plate, fuelLevel, fuelLevel
        })
    end
end)

-- Sistema de Reabastecimento
RegisterNetEvent('velocimetro:server:RefuelVehicle', function(plate)
    local src = source
    if not plate then return end
    plate = string.match(plate, "^%s*(.-)%s*$")
<<<<<<< Updated upstream

    -- Busca o combustível atual no cache do servidor para evitar exploit do cliente
    local currentFuelServer = VehicleFuelCache[plate]

=======

    -- Busca o combustível atual no cache do servidor para evitar exploit do cliente
    local currentFuelServer = VehicleFuelCache[plate]

>>>>>>> Stashed changes
    -- Se por acaso o servidor não tem no cache, tentamos buscar no banco ou definimos como max (fallback)
    if not currentFuelServer then
        if GetResourceState('oxmysql') == 'started' then
            exports.oxmysql:scalar('SELECT fuel_level FROM vehicle_fuel WHERE plate = ?', {plate}, function(fuel)
                if fuel then
                    ProcessRefuel(src, plate, fuel)
                else
                    TriggerClientEvent('velocimetro:client:Notify', src, "Veículo não registrado.")
                end
            end)
        else
            ProcessRefuel(src, plate, Config.MaxFuel) -- Fallback
        end
    else
        ProcessRefuel(src, plate, currentFuelServer)
    end
end)

function ProcessRefuel(src, plate, currentFuelServer)
    local fuelNeeded = Config.MaxFuel - currentFuelServer
<<<<<<< Updated upstream

=======

>>>>>>> Stashed changes
    if fuelNeeded <= 1.0 then
        TriggerClientEvent('velocimetro:client:Notify', src, "O tanque já está cheio!")
        return
    end

    local cost = math.floor(fuelNeeded * Config.FuelPrice)
<<<<<<< Updated upstream

    if cost <= 0 then return end -- Previne exploits de valores negativos

    if Config.CobrarAbastecimento(src, cost) then
        VehicleFuelCache[plate] = Config.MaxFuel

        if GetResourceState('oxmysql') == 'started' then
            exports.oxmysql:execute('UPDATE vehicle_fuel SET fuel_level = ? WHERE plate = ?', {Config.MaxFuel, plate})
        end

=======

    if cost <= 0 then return end -- Previne exploits de valores negativos

    if Config.CobrarAbastecimento(src, cost) then
        VehicleFuelCache[plate] = Config.MaxFuel

        if GetResourceState('oxmysql') == 'started' then
            exports.oxmysql:execute('UPDATE vehicle_fuel SET fuel_level = ? WHERE plate = ?', {Config.MaxFuel, plate})
        end

>>>>>>> Stashed changes
        TriggerClientEvent('velocimetro:client:SyncFuel', -1, plate, Config.MaxFuel)
        TriggerClientEvent('velocimetro:client:Notify', src, "Veículo abastecido com sucesso por R$"..cost)
    else
        TriggerClientEvent('velocimetro:client:Notify', src, "Dinheiro insuficiente para abastecer.")
    end
end
