-- Tablas de usuarios y autenticación
CREATE TABLE "user" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    verification_status VARCHAR(20) NOT NULL DEFAULT 'unverified',
    verification_document_url VARCHAR(255),
    verification_social_url VARCHAR(255),
    last_login TIMESTAMP WITH TIME ZONE,
    license_type VARCHAR(10), -- 'basic' or 'premium'
    license_expires_at TIMESTAMP WITH TIME ZONE,
    current_session_id VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Tabla de perfiles de usuario
CREATE TABLE user_profile (
    user_id UUID PRIMARY KEY REFERENCES "user"(id) ON DELETE CASCADE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    birth_date DATE,
    country_code VARCHAR(2),
    elo_rating INT DEFAULT 1000,
    open_elo_rating INT DEFAULT 1000,
    profile_picture_url VARCHAR(255),
    bio TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Tabla de modalidades de juego
CREATE TABLE game_mode (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(50) NOT NULL, -- 'swiss', 'round_robin', 'elimination', 'patio', etc.
    description TEXT,
    min_players INT NOT NULL,
    max_players INT,
    is_team_mode BOOLEAN NOT NULL DEFAULT TRUE,
    rules JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Tabla de organizaciones
CREATE TABLE organization (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_organization_id UUID REFERENCES organization(id),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    organization_type VARCHAR(20) NOT NULL, -- 'fid', 'federation', 'association', 'club'
    country_code VARCHAR(2),
    region VARCHAR(100),
    verification_status VARCHAR(20) NOT NULL DEFAULT 'pending',
    logo_url VARCHAR(255),
    website_url VARCHAR(255),
    contact_email VARCHAR(255),
    created_by UUID REFERENCES "user"(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Tabla de roles de usuario en organizaciones
CREATE TABLE organization_member (
    user_id UUID REFERENCES "user"(id) ON DELETE CASCADE,
    organization_id UUID REFERENCES organization(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL, -- 'admin', 'moderator', 'player', 'referee', 'fan'
    is_primary BOOLEAN DEFAULT FALSE,
    joined_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, organization_id)
);

-- Tabla de torneos
CREATE TABLE tournament (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID REFERENCES organization(id),
    game_mode_id UUID REFERENCES game_mode(id),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    tournament_type VARCHAR(50) NOT NULL,
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    location VARCHAR(255),
    is_official BOOLEAN NOT NULL DEFAULT FALSE,
    is_official_approved BOOLEAN NOT NULL DEFAULT FALSE,
    approved_by_organization_id UUID REFERENCES organization(id),
    status VARCHAR(20) NOT NULL DEFAULT 'planned',
    points_per_round INT NOT NULL DEFAULT 200,
    is_cycles_mode BOOLEAN NOT NULL DEFAULT FALSE,
    rounds_planned INT NOT NULL,
    ruleset JSONB,
    entry_fee DECIMAL(10,2),
    prize_pool DECIMAL(10,2),
    public_calendar BOOLEAN NOT NULL DEFAULT FALSE,
    created_by UUID REFERENCES "user"(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Tabla de participantes en torneos
CREATE TABLE tournament_participant (
    tournament_id UUID REFERENCES tournament(id) ON DELETE CASCADE,
    user_id UUID REFERENCES "user"(id) ON DELETE CASCADE,
    partner_user_id UUID REFERENCES "user"(id),
    team_name VARCHAR(255),
    initial_rating INT,
    final_position INT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    PRIMARY KEY (tournament_id, user_id)
);

-- Tabla de rondas de torneo
CREATE TABLE tournament_round (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID REFERENCES tournament(id) ON DELETE CASCADE,
    round_number INT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    start_time TIMESTAMP WITH TIME ZONE,
    end_time TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    UNIQUE(tournament_id, round_number)
);

-- Tabla de partidas
CREATE TABLE game (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    round_id UUID REFERENCES tournament_round(id) ON DELETE CASCADE,
    table_number INT NOT NULL,
    player1_id UUID REFERENCES "user"(id),
    player2_id UUID REFERENCES "user"(id),
    player3_id UUID REFERENCES "user"(id),
    player4_id REFERENCES "user"(id),
    team1_score INT,
    team2_score INT,
    status VARCHAR(20) NOT NULL DEFAULT 'scheduled',
    start_time TIMESTAMP WITH TIME ZONE,
    end_time TIMESTAMP WITH TIME ZONE,
    referee_id UUID REFERENCES "user"(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Tabla de resultados de partidas
CREATE TABLE match_result (
    game_id UUID REFERENCES game(id) ON DELETE CASCADE,
    team1_player1_id UUID REFERENCES "user"(id),
    team1_player2_id UUID REFERENCES "user"(id),
    team2_player1_id UUID REFERENCES "user"(id),
    team2_player2_id UUID REFERENCES "user"(id),
    team1_score INT NOT NULL,
    team2_score INT NOT NULL,
    is_draw BOOLEAN NOT NULL DEFAULT FALSE,
    reported_by UUID REFERENCES "user"(id),
    verified_by UUID REFERENCES "user"(id),
    verification_status VARCHAR(20) NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    PRIMARY KEY (game_id)
);

-- Tabla de ranking del torneo
CREATE TABLE tournament_ranking (
    tournament_id UUID REFERENCES tournament(id) ON DELETE CASCADE,
    user_id UUID REFERENCES "user"(id) ON DELETE CASCADE,
    position INT NOT NULL,
    matches_played INT NOT NULL DEFAULT 0,
    matches_won INT NOT NULL DEFAULT 0,
    matches_lost INT NOT NULL DEFAULT 0,
    matches_drawn INT NOT NULL DEFAULT 0,
    total_points_for INT NOT NULL DEFAULT 0,
    total_points_against INT NOT NULL DEFAULT 0,
    performance_rating DECIMAL(5,2),
    average_opponent_rating DECIMAL(5,2),
    last_round_played INT,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    PRIMARY KEY (tournament_id, user_id)
);

-- Tabla de historial de ratings ELO
CREATE TABLE elo_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES "user"(id) ON DELETE CASCADE,
    rating_type VARCHAR(10) NOT NULL, -- 'official' or 'open'
    old_rating INT NOT NULL,
    new_rating INT NOT NULL,
    change INT NOT NULL,
    game_id UUID REFERENCES game(id),
    tournament_id UUID REFERENCES tournament(id),
    change_reason VARCHAR(255),
    changed_by UUID REFERENCES "user"(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Tabla de ranking global
CREATE TABLE global_ranking (
    user_id UUID PRIMARY KEY REFERENCES "user"(id) ON DELETE CASCADE,
    elo_rating INT NOT NULL DEFAULT 1000,
    open_elo_rating INT NOT NULL DEFAULT 1000,
    tournaments_played INT NOT NULL DEFAULT 0,
    tournaments_won INT NOT NULL DEFAULT 0,
    matches_played INT NOT NULL DEFAULT 0,
    matches_won INT NOT NULL DEFAULT 0,
    matches_lost INT NOT NULL DEFAULT 0,
    matches_drawn INT NOT NULL DEFAULT 0,
    total_points_for INT NOT NULL DEFAULT 0,
    total_points_against INT NOT NULL DEFAULT 0,
    performance_rating DECIMAL(5,2),
    last_tournament_date TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Tabla de ranking regional
CREATE TABLE regional_ranking (
    user_id UUID REFERENCES "user"(id) ON DELETE CASCADE,
    region_code VARCHAR(10) NOT NULL,
    elo_rating INT NOT NULL DEFAULT 1000,
    position INT NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, region_code)
);

-- Tabla de licencias/subscripciones
CREATE TABLE license_subscription (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES "user"(id) ON DELETE CASCADE,
    organization_id UUID REFERENCES organization(id) ON DELETE SET NULL,
    license_type VARCHAR(10) NOT NULL, -- 'basic' or 'premium'
    payment_plan VARCHAR(10) NOT NULL, -- 'monthly' or 'annual'
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    payment_amount DECIMAL(10, 2) NOT NULL,
    payment_currency VARCHAR(3) NOT NULL DEFAULT 'USD',
    payment_receipt_url VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Tabla de características de licencia
CREATE TABLE license_feature (
    license_type VARCHAR(10) PRIMARY KEY, -- 'basic' or 'premium'
    max_organizations INT,
    max_tournaments INT,
    max_participants INT,
    available_game_types TEXT[],
    has_detailed_stats BOOLEAN NOT NULL DEFAULT FALSE,
    allow_multiple_sessions BOOLEAN NOT NULL DEFAULT FALSE,
    can_create_official_tournaments BOOLEAN NOT NULL DEFAULT FALSE,
    can_verify_players BOOLEAN NOT NULL DEFAULT FALSE
);

-- Tabla de sesiones activas
CREATE TABLE active_session (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES "user"(id) ON DELETE CASCADE,
    session_token VARCHAR(255) NOT NULL,
    ip_address VARCHAR(45) NOT NULL,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL
);

-- Tabla de notificaciones
CREATE TABLE notification (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES "user"(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    notification_type VARCHAR(50) NOT NULL,
    related_entity_type VARCHAR(50),
    related_entity_id UUID,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Tabla de solicitudes de verificación
CREATE TABLE verification_request (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES "user"(id) ON DELETE CASCADE,
    organization_id UUID REFERENCES organization(id) ON DELETE CASCADE,
    request_type VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    document_url VARCHAR(255),
    social_verification_url VARCHAR(255),
    reviewed_by UUID REFERENCES "user"(id),
    review_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Tabla de solicitudes de aval
CREATE TABLE tournament_approval_request (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID REFERENCES tournament(id) ON DELETE CASCADE,
    requesting_organization_id UUID REFERENCES organization(id) ON DELETE CASCADE,
    approving_organization_id UUID REFERENCES organization(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    requested_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    decided_at TIMESTAMP WITH TIME ZONE,
    decided_by UUID REFERENCES "user"(id),
    notes TEXT
);

-- Insertar características de licencias
INSERT INTO license_feature (license_type, max_organizations, max_tournaments, max_participants, available_game_types, has_detailed_stats, allow_multiple_sessions, can_create_official_tournaments, can_verify_players)
VALUES 
('basic', 1, 1, 50, '{"swiss"}', FALSE, FALSE, FALSE, FALSE),
('premium', 10, 5, 1000, '{"swiss", "round_robin", "elimination", "double_elimination", "patio"}', TRUE, TRUE, TRUE, TRUE);

-- Insertar modalidades de juego básicas
INSERT INTO game_mode (id, name, description, min_players, max_players, is_team_mode, rules)
VALUES
(gen_random_uuid(), 'swiss', 'Sistema Suizo', 4, NULL, TRUE, '{"rounds": 5, "pairing": "swiss", "scoring": 200}'),
(gen_random_uuid(), 'round_robin', 'Liguilla', 4, NULL, TRUE, '{"rounds": "all_vs_all", "pairing": "sequential", "scoring": 200}'),
(gen_random_uuid(), 'elimination', 'Eliminación directa', 4, NULL, TRUE, '{"rounds": "until_winner", "pairing": "elimination", "scoring": 200}'),
(gen_random_uuid(), 'patio', 'Sistema de patio', 4, NULL, TRUE, '{"rounds": 10, "pairing": "random", "scoring": "cycles"}');
