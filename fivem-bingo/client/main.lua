local uiOpen = false

-- Alterna a UI
local function ToggleUI(state)
    uiOpen = state
    SetNuiFocus(state, state)
    SendNUIMessage({
        type = "toggleUI",
        state = state
    })
end

-- Comando /bingo
RegisterCommand("bingo", function()
    ToggleUI(not uiOpen)
end)

-- Notificações simples
RegisterNetEvent("bingo:client:Notify", function(msg)
    -- TODO: Troque para notificação do seu framework (ex: QBCore.Functions.Notify)
    print("[Bingo Notify]: " .. msg)
    -- Exemplo nativo FiveM:
    SetNotificationTextEntry("STRING")
    AddTextComponentString(msg)
    DrawNotification(false, false)
end)

-- Jogo Iniciado
RegisterNetEvent("bingo:client:GameStarted", function()
    SendNUIMessage({
        type = "gameStarted"
    })
end)

-- Fim de jogo
RegisterNetEvent("bingo:client:GameEnded", function(msg)
    SendNUIMessage({
        type = "gameEnded",
        message = msg
    })
    TriggerEvent("bingo:client:Notify", msg)
end)

-- Atualizar Cartela Comprada
RegisterNetEvent("bingo:client:TicketPurchased", function(matrix, prizePool)
    SendNUIMessage({
        type = "updateTicket",
        matrix = matrix,
        prizePool = prizePool
    })
    TriggerEvent("bingo:client:Notify", "Cartela comprada com sucesso!")
end)

-- Receber Novo Número Sorteado
RegisterNetEvent("bingo:client:NumberDrawn", function(number, drawnList, prizePool)
    SendNUIMessage({
        type = "numberDrawn",
        number = number,
        drawnList = drawnList,
        prizePool = prizePool
    })
end)

-- ==========================================
-- NUI Callbacks
-- ==========================================

-- Fechar UI
RegisterNUICallback("close", function(data, cb)
    ToggleUI(false)
    cb('ok')
end)

-- Comprar Cartela
RegisterNUICallback("buyTicket", function(data, cb)
    TriggerServerEvent("bingo:server:BuyTicket")
    cb('ok')
end)

-- Gritar BINGO
RegisterNUICallback("shoutBingo", function(data, cb)
    TriggerServerEvent("bingo:server:ShoutBingo")
    cb('ok')
end)
