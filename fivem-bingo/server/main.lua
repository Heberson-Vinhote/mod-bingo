local ActiveGame = {
    id = nil,
    status = "inativo", -- inativo, aguardando, rodando
    prize_pool = 0,
    drawn_numbers = {},
    players = {}
}

-- Helpers
local function ShuffleTable(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
end

local function GenerateColumn(min, max, count)
    local nums = {}
    for i = min, max do table.insert(nums, i) end
    ShuffleTable(nums)
    local col = {}
    for i = 1, count do table.insert(col, nums[i]) end
    return col
end

local function GenerateTicketMatrix()
    -- B: 1-15, I: 16-30, N: 31-45, G: 46-60, O: 61-75
    local b = GenerateColumn(1, 15, 5)
    local i = GenerateColumn(16, 30, 5)
    local n = GenerateColumn(31, 45, 5)
    local g = GenerateColumn(46, 60, 5)
    local o = GenerateColumn(61, 75, 5)

    -- Espaço livre no meio (linha 3, coluna 3) - O NUI cuidará de marcar isso
    n[3] = "LIVRE"

    return {
        {b[1], i[1], n[1], g[1], o[1]},
        {b[2], i[2], n[2], g[2], o[2]},
        {b[3], i[3], n[3], g[3], o[3]},
        {b[4], i[4], n[4], g[4], o[4]},
        {b[5], i[5], n[5], g[5], o[5]}
    }
end

local function SaveTicketToDB(game_id, player_identifier, matrix, cb)
    local jsonMatrix = json.encode(matrix)

    -- Exemplo de integração usando oxmysql (framework mais comum do FiveM)
    -- Caso use outro (como ghmattimysql ou mysql-async), adapte a sintaxe.
    if GetResourceState('oxmysql') == 'started' then
        exports.oxmysql:insert('INSERT INTO bingo_tickets (game_id, player_identifier, ticket_matrix) VALUES (?, ?, ?)', {
            game_id, player_identifier, jsonMatrix
        }, function(id)
            if cb then cb(id) end
        end)
    else
        -- Fallback mock caso o banco não esteja rodando
        local fakeTicketId = math.random(1000, 9999)
        print(string.format("[Bingo DB - Mock] Inserindo cartela para jogo %s, jogador %s: %s", tostring(game_id), player_identifier, jsonMatrix))
        if cb then cb(fakeTicketId) end
    end
end

local function UpdateGameStatusInDB(game_id, status, prize_pool)
    if game_id and GetResourceState('oxmysql') == 'started' then
        exports.oxmysql:execute('UPDATE bingo_games SET status = ?, prize_pool = ? WHERE id = ?', {
            status, prize_pool, game_id
        })
    end
end


local function DrawNumberLoop()
    CreateThread(function()
        while ActiveGame.status == "rodando" do
            Wait(Config.DrawInterval)

            if ActiveGame.status ~= "rodando" then break end

            local available_numbers = {}
            for i = 1, 75 do
                local already_drawn = false
                for _, num in ipairs(ActiveGame.drawn_numbers) do
                    if num == i then already_drawn = true; break end
                end
                if not already_drawn then table.insert(available_numbers, i) end
            end

            if #available_numbers == 0 then
                ActiveGame.status = "finalizado"
                UpdateGameStatusInDB(ActiveGame.id, "finalizado", ActiveGame.prize_pool)
                TriggerClientEvent("bingo:client:GameEnded", -1, "Empate! Todos os números foram sorteados.")
                break
            end

            local drawn = available_numbers[math.random(#available_numbers)]
            table.insert(ActiveGame.drawn_numbers, drawn)

            TriggerClientEvent("bingo:client:NumberDrawn", -1, drawn, ActiveGame.drawn_numbers, ActiveGame.prize_pool)
        end
    end)
end

local function StartGame()
    if ActiveGame.status == "aguardando" then
        ActiveGame.status = "rodando"
        UpdateGameStatusInDB(ActiveGame.id, "rodando", ActiveGame.prize_pool)
        TriggerClientEvent("bingo:client:GameStarted", -1)
        DrawNumberLoop()
    end
end

-- Comprar Cartela
RegisterNetEvent("bingo:server:BuyTicket", function()
    local src = source
    local identifier = tostring(src) -- Identificador simplificado

    if ActiveGame.status == "inativo" or ActiveGame.status == "finalizado" then
        -- Inicia um novo jogo aguardando
        ActiveGame.status = "aguardando"
        ActiveGame.prize_pool = 0
        ActiveGame.drawn_numbers = {}
        ActiveGame.players = {}

        if GetResourceState('oxmysql') == 'started' then
            exports.oxmysql:insert('INSERT INTO bingo_games (status, prize_pool) VALUES (?, ?)', {
                'aguardando', 0.00
            }, function(id)
                ActiveGame.id = id
            end)
        else
            ActiveGame.id = math.random(10000, 99999)
        end

        -- Inicia o jogo após 30 segundos
        SetTimeout(30000, StartGame)
        TriggerClientEvent("bingo:client:Notify", -1, "Um novo jogo de bingo começará em 30 segundos! Compre suas cartelas!")
    end

    if ActiveGame.status == "rodando" then
        TriggerClientEvent("bingo:client:Notify", src, "O jogo já está rodando, aguarde a próxima rodada.")
        return
    end

    if Config.CobrarJogador(src, Config.TicketPrice) then
        local addedToPool = Config.TicketPrice * Config.PrizePoolPercentage
        ActiveGame.prize_pool = ActiveGame.prize_pool + addedToPool

        local matrix = GenerateTicketMatrix()
        ActiveGame.players[identifier] = matrix

        SaveTicketToDB(ActiveGame.id, identifier, matrix, function(ticketId)
             TriggerClientEvent("bingo:client:TicketPurchased", src, matrix, ActiveGame.prize_pool)
        end)
    else
        TriggerClientEvent("bingo:client:Notify", src, "Você não tem dinheiro suficiente.")
    end
end)

-- Validar Bingo
RegisterNetEvent("bingo:server:ShoutBingo", function()
    local src = source
    local identifier = tostring(src)

    if ActiveGame.status ~= "rodando" then return end

    local matrix = ActiveGame.players[identifier]
    if not matrix then return end

    local isWinner = true

    for row = 1, 5 do
        for col = 1, 5 do
            local num = matrix[row][col]
            if num ~= "LIVRE" then
                local found = false
                for _, drawn in ipairs(ActiveGame.drawn_numbers) do
                    if num == drawn then
                        found = true
                        break
                    end
                end
                if not found then
                    isWinner = false
                    break
                end
            end
        end
        if not isWinner then break end
    end

    if isWinner then
        ActiveGame.status = "finalizado"
        UpdateGameStatusInDB(ActiveGame.id, "finalizado", ActiveGame.prize_pool)
        Config.PagarVencedor(src, ActiveGame.prize_pool)
        TriggerClientEvent("bingo:client:GameEnded", -1, string.format("O Jogador %s ganhou o BINGO! Prêmio: R$%.2f", GetPlayerName(src), ActiveGame.prize_pool))
    else
        TriggerClientEvent("bingo:client:Notify", src, "Cartela inválida! Você ainda não completou.")
    end
end)
