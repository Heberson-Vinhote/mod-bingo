Config = {}

-- ==========================================
-- Configurações Gerais de Combustível
-- ==========================================

-- Capacidade máxima de combustível
Config.MaxFuel = 100.0

-- Multiplicador base de consumo de combustível. Aumente para gastar mais rápido.
Config.FuelConsumptionMultiplier = 0.5

-- ==========================================
-- Consumo de combustível por classe de veículo
-- O consumo baseia-se na rotação do motor (RPM).
-- Classes do GTA V:
-- 0-7,9-12 (Carros), 8 (Motos), 13 (Bicicletas), 14 (Barcos), 15 (Helicópteros), 16 (Aviões), etc.
-- ==========================================
Config.ClassFuelUsage = {
    [0] = 1.0, -- Compacts
    [1] = 1.0, -- Sedans
    [2] = 1.2, -- SUVs
    [3] = 1.1, -- Coupes
    [4] = 1.2, -- Muscle
    [5] = 1.3, -- Sports Classics
    [6] = 1.5, -- Sports
    [7] = 2.0, -- Super
    [8] = 0.6, -- Motos
    [9] = 1.5, -- Off-road
    [10] = 1.2, -- Industrial
    [11] = 1.2, -- Utility
    [12] = 1.5, -- Vans
    [13] = 0.0, -- Cycles (Bicicletas não gastam)
    [14] = 2.0, -- Boats (Barcos)
    [15] = 2.5, -- Helicopters (Helicópteros)
    [16] = 3.0, -- Planes (Aviões)
    [17] = 1.2, -- Service
    [18] = 1.5, -- Emergency
    [19] = 1.5, -- Military
    [20] = 1.5, -- Commercial
    [21] = 0.0  -- Trains
}

-- Fallback para qualquer classe que falte
Config.DefaultFuelUsage = 1.0

-- ==========================================
-- Postos de Gasolina (Refuel)
-- ==========================================
-- Preço do litro de combustível
Config.FuelPrice = 5

-- Tecla de interação (Padrão 38 = E)
Config.InteractKey = 38

-- Posições dos postos de gasolina (Exemplo de alguns postos)
Config.GasStations = {
    vector3(265.0, -1261.0, 29.0),
    vector3(819.0, -1028.0, 26.0),
    vector3(1208.0, -1402.0, 35.0),
    vector3(1181.0, -330.0, 69.0),
    vector3(620.0, 269.0, 103.0),
    vector3(2581.0, 362.0, 108.0),
    vector3(176.0, 6602.0, 31.0),
    vector3(-319.0, -1471.0, 30.0),
    vector3(-70.0, -1761.0, 29.0)
    -- Adicione mais coordenadas de postos de gasolina aqui
}

-- Distância máxima para aceitar o comando de abastecer em um posto
Config.RefuelDistance = 5.0

-- ==========================================
-- Funções Bridge (Pagamento)
-- ==========================================

-- Retorna true se o jogador foi cobrado com sucesso
function Config.CobrarAbastecimento(jogadorID, valor)
    -- TODO: Adicione a lógica do seu framework aqui (vRP, QBCore, ESX, etc.)
    -- Exemplo QBCore:
    -- local Player = QBCore.Functions.GetPlayer(jogadorID)
    -- if Player.Functions.RemoveMoney('cash', valor, "fuel") then return true else return false end

    print(string.format("[Velocimetro] Cobrando %d do jogador %s pelo combustível.", valor, jogadorID))
    return true -- Standalone default para testes
end
