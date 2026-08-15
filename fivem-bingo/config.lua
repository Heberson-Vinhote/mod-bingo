Config = {}

-- ==========================================
-- Configurações Gerais do Bingo
-- ==========================================

-- Preço de cada cartela
Config.TicketPrice = 500

-- Tempo de intervalo entre o sorteio de cada número (em milissegundos)
-- Ex: 5000 = 5 segundos
Config.DrawInterval = 5000

-- Porcentagem do valor da compra que vai para o prêmio total
-- Ex: 0.8 significa que 80% do valor vai para o prêmio e 20% é "taxa"
Config.PrizePoolPercentage = 0.8

-- ==========================================
-- Funções de Ponte (Bridge) para Frameworks
-- ==========================================

-- Esta função será chamada no servidor quando um jogador tentar comprar uma cartela.
-- Retorne `true` se o jogador tiver dinheiro e for cobrado com sucesso, `false` caso contrário.
function Config.CobrarJogador(jogadorID, valor)
    -- TODO: Adicione a lógica do seu framework aqui (vRP, QBCore, ESX, etc.)
    -- Exemplo QBCore:
    -- local Player = QBCore.Functions.GetPlayer(jogadorID)
    -- if Player.Functions.RemoveMoney('cash', valor, "bingo-ticket") then return true else return false end

    print(string.format("[Bingo] Cobrando %d do jogador %s (Modifique Config.CobrarJogador no config.lua)", valor, jogadorID))
    return true -- Permite a compra por padrão no modo standalone para testes
end

-- Esta função será chamada no servidor quando um jogador ganhar o bingo.
-- Adicione o dinheiro ao jogador.
function Config.PagarVencedor(jogadorID, valor)
    -- TODO: Adicione a lógica do seu framework aqui (vRP, QBCore, ESX, etc.)
    -- Exemplo QBCore:
    -- local Player = QBCore.Functions.GetPlayer(jogadorID)
    -- Player.Functions.AddMoney('cash', valor, "bingo-win")

    print(string.format("[Bingo] Pagando %d ao jogador %s pela vitória! (Modifique Config.PagarVencedor no config.lua)", valor, jogadorID))
end
