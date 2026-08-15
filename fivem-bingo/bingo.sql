CREATE TABLE IF NOT EXISTS bingo_games (
    id INT AUTO_INCREMENT PRIMARY KEY,
    status VARCHAR(50) DEFAULT 'aguardando', -- 'aguardando', 'rodando', 'finalizado'
    prize_pool DECIMAL(10, 2) DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS bingo_tickets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    game_id INT NOT NULL,
    player_identifier VARCHAR(100) NOT NULL,
    ticket_matrix JSON NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (game_id) REFERENCES bingo_games(id) ON DELETE CASCADE
);
