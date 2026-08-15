let currentMatrix = null;
let drawnNumbers = [];

const container = document.getElementById('bingo-container');
const closeBtn = document.getElementById('close-btn');
const buyBtn = document.getElementById('buy-btn');
const bingoBtn = document.getElementById('bingo-btn');
const ticketGrid = document.getElementById('ticket-grid');
const prizePoolText = document.getElementById('prize-pool');
const lastNumberText = document.getElementById('last-number');
const historyList = document.getElementById('drawn-history');

// Comunicação NUI
window.addEventListener('message', (event) => {
    const data = event.data;

    if (data.type === 'toggleUI') {
        if (data.state) {
            container.classList.remove('hidden');
        } else {
            container.classList.add('hidden');
        }
    } else if (data.type === 'gameStarted') {
        // Jogo iniciou
        buyBtn.disabled = true;
        buyBtn.innerText = "Jogo em Andamento";
    } else if (data.type === 'gameEnded') {
        // Fim de jogo
        buyBtn.disabled = false;
        buyBtn.innerText = "Comprar Cartela (R$ 500)";
        bingoBtn.disabled = true;
        currentMatrix = null;
        drawnNumbers = [];
        resetUI();
    } else if (data.type === 'updateTicket') {
        currentMatrix = data.matrix;
        updatePrizePool(data.prizePool);
        renderTicket();
        buyBtn.disabled = true;
        buyBtn.innerText = "Cartela Comprada!";
    } else if (data.type === 'numberDrawn') {
        drawnNumbers = data.drawnList;
        lastNumberText.innerText = data.number;
        updateHistory();
        updatePrizePool(data.prizePool);
        checkTicketForMarks();
    }
});

// Ações dos Botões
closeBtn.addEventListener('click', () => {
    fetch(`https://${GetParentResourceName()}/close`, { method: 'POST' });
});

buyBtn.addEventListener('click', () => {
    fetch(`https://${GetParentResourceName()}/buyTicket`, { method: 'POST' });
});

bingoBtn.addEventListener('click', () => {
    fetch(`https://${GetParentResourceName()}/shoutBingo`, { method: 'POST' });
});

function resetUI() {
    ticketGrid.innerHTML = '';
    prizePoolText.innerText = "R$ 0,00";
    lastNumberText.innerText = "--";
    historyList.innerHTML = '';
}

function updatePrizePool(val) {
    prizePoolText.innerText = `R$ ${val.toFixed(2).replace('.', ',')}`;
}

function renderTicket() {
    ticketGrid.innerHTML = '';
    for (let row = 0; row < 5; row++) {
        for (let col = 0; col < 5; col++) {
            const cell = document.createElement('div');
            cell.classList.add('cell');

            const val = currentMatrix[row][col];
            cell.dataset.row = row;
            cell.dataset.col = col;
            cell.dataset.val = val;

            if (val === "LIVRE") {
                cell.innerText = "FREE";
                cell.classList.add('free-space', 'marked');
            } else {
                cell.innerText = val;
            }

            ticketGrid.appendChild(cell);
        }
    }
}

function updateHistory() {
    historyList.innerHTML = '';
    // Pega os ultimos 5
    const last5 = drawnNumbers.slice(-5).reverse();
    last5.forEach(num => {
        const li = document.createElement('li');
        li.innerText = num;
        historyList.appendChild(li);
    });
}

function checkTicketForMarks() {
    if (!currentMatrix) return;

    let markedCount = 0;
    const cells = document.querySelectorAll('.cell');

    cells.forEach(cell => {
        const val = cell.dataset.val;
        if (val === "LIVRE") {
            markedCount++;
        } else {
            const num = parseInt(val);
            if (drawnNumbers.includes(num)) {
                cell.classList.add('marked');
                markedCount++;
            }
        }
    });

    // Se todos os 25 espaços estiverem marcados
    if (markedCount === 25) {
        bingoBtn.disabled = false;
    }
}
