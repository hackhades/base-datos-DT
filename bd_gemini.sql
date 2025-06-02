-- Eliminar tablas existentes si es necesario (para desarrollo)
-- Considerar el orden por las dependencias de FK
DROP TABLE IF EXISTS game_player_elo_changes CASCADE;
DROP TABLE IF EXISTS game_results CASCADE;
DROP TABLE IF EXISTS tournament_round_pairings CASCADE; -- Si se gestionan parejas explícitamente antes de la partida
DROP TABLE IF EXISTS tournament_rounds CASCADE;
DROP TABLE IF EXISTS tournament_participants CASCADE;
DROP TABLE IF EXISTS tournament_arbiters CASCADE;
DROP TABLE IF EXISTS tournament_endorsements CASCADE;
DROP TABLE IF EXISTS tournaments CASCADE;
DROP TABLE IF EXISTS tournament_modalities CASCADE;
DROP TABLE IF EXISTS ranking_entries CASCADE;
DROP TABLE IF EXISTS published_rankings CASCADE;
DROP TABLE IF EXISTS elo_history CASCADE;
DROP TABLE IF EXISTS published_events CASCADE;
DROP TABLE IF EXISTS licenses CASCADE;
DROP TABLE IF EXISTS license_types CASCADE;
DROP TABLE IF EXISTS organization_verification_requests CASCADE;
DROP TABLE IF EXISTS organization_staff CASCADE;
DROP TABLE IF EXISTS organizations CASCADE;
DROP TABLE IF EXISTS user_roles CASCADE;
DROP TABLE IF EXISTS roles CASCADE;
DROP TABLE IF EXISTS sessions CASCADE;
DROP TABLE IF EXISTS users CASCADE;

DROP TYPE IF EXISTS organization_type_enum CASCADE;
DROP TYPE IF EXISTS license_status_enum CASCADE;
DROP TYPE IF EXISTS payment_interval_enum CASCADE;
DROP TYPE IF EXISTS tournament_status_enum CASCADE;
DROP TYPE IF EXISTS game_outcome_enum CASCADE; -- Cambiado de game_result_enum
DROP TYPE IF EXISTS ranking_category_enum CASCADE;
DROP TYPE IF EXISTS verification_status_enum CASCADE;
DROP TYPE IF EXISTS round_scoring_type_enum CASCADE;
DROP TYPE IF EXISTS endorsement_status_enum CASCADE;
DROP TYPE IF EXISTS elo_impact_level_enum CASCADE;


-- TIPOS ENUMERADOS
CREATE TYPE organization_type_enum AS ENUM ('FID', 'FEDERATION', 'ASSOCIATION', 'CLUB');
CREATE TYPE license_status_enum AS ENUM ('ACTIVE', 'INACTIVE', 'PENDING_PAYMENT', 'EXPIRED', 'CANCELLED');
CREATE TYPE payment_interval_enum AS ENUM ('MONTHLY', 'ANNUAL');
CREATE TYPE tournament_status_enum AS ENUM ('PLANNED', 'REGISTRATION_OPEN', 'REGISTRATION_CLOSED', 'ONGOING', 'COMPLETED', 'CANCELLED', 'PENDING_ENDORSEMENT');
CREATE TYPE game_outcome_enum AS ENUM ('TEAM1_WIN', 'TEAM2_WIN', 'DRAW', 'FORFEIT_TEAM1_WINS', 'FORFEIT_TEAM2_WINS', 'PENDING', 'BYE'); -- Para resultados de partida en pareja
CREATE TYPE ranking_category_enum AS ENUM (
    'UNIVERSAL_FID',        -- Ranking mundial oficial FIDE
    'CONTINENTAL_FID',      -- Ranking continental oficial FIDE (si aplica)
    'NATIONAL_FEDERATION',  -- Ranking nacional oficial de una Federación
    'REGIONAL_ASSOCIATION', -- Ranking regional/estatal oficial de una Asociación
    'LOCAL_CLUB',           -- Ranking local oficial de un Club
    'OPEN_AMATEUR'          -- Rankings abiertos no oficiales
);
CREATE TYPE verification_status_enum AS ENUM ('PENDING', 'APPROVED', 'REJECTED', 'NEEDS_INFO');
CREATE TYPE round_scoring_type_enum AS ENUM ('POINTS_TARGET', 'CYCLES_TARGET'); -- Para rondas de dominó
CREATE TYPE endorsement_status_enum AS ENUM ('REQUESTED', 'APPROVED', 'REJECTED', 'CANCELLED_BY_REQUESTER');
CREATE TYPE elo_impact_level_enum AS ENUM ('NONE','OPEN_ELO_ONLY', 'CLUB', 'ASSOCIATION', 'FEDERATION', 'FID'); -- Nivel de impacto ELO de una partida


-- TABLAS
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    date_of_birth DATE,
    country_code CHAR(2), -- ISO 3166-1 alpha-2 (ej. 'ES', 'VE', 'US') para filtros de ranking
    fid_id VARCHAR(50) UNIQUE,
    profile_picture_url TEXT,
    elo_official INT DEFAULT 1200, -- ELO para rankings oficiales (potencialmente el más alto que tenga)
    elo_open INT DEFAULT 1200,     -- ELO para rankings abiertos/amateur
    is_verified_identity BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE sessions (
    id UUID PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    expires_at TIMESTAMPTZ NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_sessions_user_id ON sessions(user_id);

CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT
);

CREATE TABLE user_roles (
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id INTEGER NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, role_id)
);
CREATE INDEX idx_user_roles_role_id ON user_roles(role_id);

CREATE TABLE organizations (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    type organization_type_enum NOT NULL,
    parent_organization_id INTEGER REFERENCES organizations(id) ON DELETE SET NULL,
    country_code CHAR(2),
    region_or_state VARCHAR(100),
    city VARCHAR(100),
    address TEXT,
    contact_email VARCHAR(255),
    contact_phone VARCHAR(50),
    website_url TEXT,
    logo_url TEXT,
    founded_date DATE,
    description TEXT,
    is_officially_verified BOOLEAN DEFAULT FALSE,
    verified_by_organization_id INTEGER REFERENCES organizations(id) ON DELETE SET NULL,
    verified_by_user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    verification_date TIMESTAMPTZ,
    verification_document_url TEXT,
    social_media_link_for_verification TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (name, type, parent_organization_id)
);
CREATE INDEX idx_organizations_type ON organizations(type);
CREATE INDEX idx_organizations_parent_id ON organizations(parent_organization_id);
CREATE INDEX idx_organizations_country_code ON organizations(country_code);

CREATE TABLE organization_verification_requests (
    id SERIAL PRIMARY KEY,
    requesting_organization_id INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    approving_organization_id INTEGER REFERENCES organizations(id) ON DELETE SET NULL,
    status verification_status_enum DEFAULT 'PENDING',
    submitted_by_user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reviewed_by_user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    submission_notes TEXT,
    review_notes TEXT,
    submitted_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    reviewed_at TIMESTAMPTZ
);
CREATE INDEX idx_org_ver_req_requesting_org ON organization_verification_requests(requesting_organization_id);
CREATE INDEX idx_org_ver_req_approving_org ON organization_verification_requests(approving_organization_id);

CREATE TABLE organization_staff (
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    organization_id INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    role_in_organization VARCHAR(100),
    is_primary_contact BOOLEAN DEFAULT FALSE,
    can_manage_licenses BOOLEAN DEFAULT FALSE,
    can_manage_tournaments BOOLEAN DEFAULT FALSE,
    can_manage_endorsements BOOLEAN DEFAULT FALSE, -- Puede aprobar/rechazar solicitudes de aval de orgs hijas
    can_approve_children_orgs BOOLEAN DEFAULT FALSE,
    added_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, organization_id)
);
CREATE INDEX idx_organization_staff_organization_id ON organization_staff(organization_id);

CREATE TABLE license_types (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    price_monthly NUMERIC(10,2) NOT NULL,
    price_annual NUMERIC(10,2) NOT NULL,
    features JSONB, -- { "max_concurrent_tournaments": 1, "can_publish_events": false, "max_participants_per_tournament": 64, ... }
    max_concurrent_sessions INT DEFAULT 1,
    is_available BOOLEAN DEFAULT TRUE
);

CREATE TABLE licenses (
    id SERIAL PRIMARY KEY,
    license_type_id INTEGER NOT NULL REFERENCES license_types(id) ON DELETE RESTRICT,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    organization_id INTEGER REFERENCES organizations(id) ON DELETE CASCADE,
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ NOT NULL,
    payment_interval payment_interval_enum NOT NULL,
    status license_status_enum NOT NULL DEFAULT 'PENDING_PAYMENT',
    auto_renew BOOLEAN DEFAULT FALSE,
    transaction_id VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_license_owner CHECK ( (user_id IS NOT NULL AND organization_id IS NULL) OR (user_id IS NULL AND organization_id IS NOT NULL) )
);
CREATE INDEX idx_licenses_user_id ON licenses(user_id);
CREATE INDEX idx_licenses_organization_id ON licenses(organization_id);
CREATE INDEX idx_licenses_end_date ON licenses(end_date);

-- Tabla para modalidades de torneo
CREATE TABLE tournament_modalities (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL, -- 'Sistema Suizo', 'Round Robin (Liguilla)', 'Eliminatoria (Llave)', 'Patio', 'Ciclos Fijos'
    description TEXT,
    requires_pairing_algorithm BOOLEAN DEFAULT TRUE, -- True para suizo, liguilla, etc. False para 'Patio' donde puede ser más libre.
    min_players_per_game INTEGER DEFAULT 4, -- Para dominó usualmente 4
    max_players_per_game INTEGER DEFAULT 4
);

CREATE TABLE tournaments (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    organizer_organization_id INTEGER REFERENCES organizations(id) ON DELETE SET NULL,
    organizer_user_id INTEGER REFERENCES users(id) ON DELETE SET NULL, -- Para torneos de aficionados con licencia
    tournament_modality_id INTEGER NOT NULL REFERENCES tournament_modalities(id) ON DELETE RESTRICT,
    start_datetime TIMESTAMPTZ NOT NULL,
    end_datetime TIMESTAMPTZ,
    location_venue_name VARCHAR(255),
    location_address TEXT,
    location_city VARCHAR(100),
    location_country_code CHAR(2),
    status tournament_status_enum DEFAULT 'PLANNED',
    max_participants INTEGER,
    min_rounds INTEGER, -- Número mínimo de rondas que el organizador planea
    max_rounds INTEGER, -- Número máximo de rondas o número fijo si min_rounds = max_rounds
    registration_deadline TIMESTAMPTZ,
    entry_fee NUMERIC(8,2) DEFAULT 0.00,
    rules_details TEXT,
    prize_details TEXT,
    banner_image_url TEXT,
    created_by_user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_tournament_organizer CHECK ( (organizer_organization_id IS NOT NULL AND organizer_user_id IS NULL) OR (organizer_organization_id IS NULL AND organizer_user_id IS NOT NULL) ),
    CONSTRAINT chk_tournament_rounds_logic CHECK (min_rounds IS NULL OR max_rounds IS NULL OR min_rounds <= max_rounds)
);
CREATE INDEX idx_tournaments_organizer_organization_id ON tournaments(organizer_organization_id);
CREATE INDEX idx_tournaments_organizer_user_id ON tournaments(organizer_user_id);
CREATE INDEX idx_tournaments_status ON tournaments(status);
CREATE INDEX idx_tournaments_modality_id ON tournaments(tournament_modality_id);

-- Tabla para gestionar los avales de torneos por organizaciones superiores
CREATE TABLE tournament_endorsements (
    id SERIAL PRIMARY KEY,
    tournament_id INTEGER NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
    -- Organización que organiza el torneo (para referencia, aunque ya está en tournaments)
    requesting_organization_id INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    -- Organización a la que se solicita el aval (ej. Club pide a Asociación, Asociación a Federación, Federación a FID)
    endorsing_organization_id INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    status endorsement_status_enum DEFAULT 'REQUESTED',
    requested_by_user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE RESTRICT, -- Staff de la org solicitante
    reviewed_by_user_id INTEGER REFERENCES users(id) ON DELETE SET NULL, -- Staff de la org que avala
    request_notes TEXT,
    review_notes TEXT,
    requested_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    reviewed_at TIMESTAMPTZ,
    -- Nivel de impacto ELO que este aval otorga a las partidas del torneo
    elo_impact elo_impact_level_enum NOT NULL,
    UNIQUE (tournament_id, endorsing_organization_id) -- Un torneo solo puede ser avalado una vez por la misma org superior
);
CREATE INDEX idx_tournament_endorsements_tournament_id ON tournament_endorsements(tournament_id);
CREATE INDEX idx_tournament_endorsements_endorsing_org_id ON tournament_endorsements(endorsing_organization_id);


CREATE TABLE tournament_participants (
    id SERIAL PRIMARY KEY,
    tournament_id INTEGER NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    registration_datetime TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    initial_elo_official INT,
    initial_elo_open INT,
    final_ranking_position INTEGER,
    total_points_achieved NUMERIC(6,2) DEFAULT 0.00, -- Puntos de partida ganadas/empatadas (e.g., 1 por victoria, 0.5 por empate)
    
    -- Métricas estadísticas específicas del dominó (ejemplos, necesitas definir las tuyas)
    stat_games_played INTEGER DEFAULT 0,
    stat_games_won INTEGER DEFAULT 0,
    stat_games_lost INTEGER DEFAULT 0,
    stat_games_drawn INTEGER DEFAULT 0,
    stat_points_for INTEGER DEFAULT 0,         -- Suma de puntos hechos por el jugador (o su pareja cuando jugó)
    stat_points_against INTEGER DEFAULT 0,     -- Suma de puntos recibidos por el jugador (o su pareja)
    stat_positive_differential NUMERIC(8,2),   -- (Puntos For - Puntos Against) / Partidas Jugadas u otra fórmula
    stat_effectiveness_rating NUMERIC(5,4),    -- e.g. (Partidas Ganadas / Partidas Jugadas)
    stat_sum_elo_opponents INT,                -- Suma de ELO de oponentes enfrentados (para desempates)
    stat_average_elo_opponents NUMERIC(6,2),
    stat_buchholz_total NUMERIC(8,2),          -- Suma de puntos de los oponentes
    stat_buchholz_median NUMERIC(8,2),         -- Buchholz quitando el mejor y peor oponente
    stat_sonneborn_berger NUMERIC(10,2),       -- Suma de puntos de oponentes derrotados + 0.5 * suma de puntos de oponentes empatados
    -- ... otros 13-N campos estadísticos que necesites ...
    -- stat_custom_metric_1 NUMERIC(10,2),
    -- stat_custom_metric_2 NUMERIC(10,2),

    is_confirmed BOOLEAN DEFAULT FALSE,
    payment_status VARCHAR(50) DEFAULT 'NOT_APPLICABLE',
    notes TEXT, -- Notas sobre el participante, ej. "Llegó tarde a ronda 1"
    UNIQUE (tournament_id, user_id)
);
CREATE INDEX idx_tournament_participants_user_id ON tournament_participants(user_id);

CREATE TABLE tournament_arbiters (
    tournament_id INTEGER NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_in_tournament VARCHAR(100) DEFAULT 'Arbiter',
    PRIMARY KEY (tournament_id, user_id)
);
CREATE INDEX idx_tournament_arbiters_user_id ON tournament_arbiters(user_id);

CREATE TABLE tournament_rounds (
    id SERIAL PRIMARY KEY,
    tournament_id INTEGER NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
    round_number INTEGER NOT NULL,
    start_datetime TIMESTAMPTZ,
    is_completed BOOLEAN DEFAULT FALSE,
    pairing_generated_at TIMESTAMPTZ,
    -- Especificaciones de cómo se juega ESTA ronda
    scoring_type round_scoring_type_enum NOT NULL, -- 'POINTS_TARGET' o 'CYCLES_TARGET'
    target_score_or_cycles INTEGER NOT NULL, -- e.g., 100, 200 (puntos) o 1, 2 (ciclos, donde 1 ciclo = 4 manos)
    notes TEXT, -- Cualquier detalle específico de la ronda
    UNIQUE (tournament_id, round_number)
);

-- Opcional: Tabla explícita para pareos si el sistema los genera antes de las partidas
-- CREATE TABLE tournament_round_pairings (
--     id SERIAL PRIMARY KEY,
--     round_id INTEGER NOT NULL REFERENCES tournament_rounds(id) ON DELETE CASCADE,
--     board_number INTEGER,
--     team1_player1_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
--     team1_player2_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
--     team2_player1_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
--     team2_player2_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
--     is_bye BOOLEAN DEFAULT FALSE, -- Si una pareja tiene BYE
--     game_id INTEGER REFERENCES game_results(id) ON DELETE SET NULL, -- Enlazar al resultado una vez jugado
--     UNIQUE (round_id, board_number),
--     CONSTRAINT chk_pairing_players_distinct CHECK (
--         team1_player1_id <> team1_player2_id AND
--         team1_player1_id <> team2_player1_id AND
--         team1_player1_id <> team2_player2_id AND
--         team1_player2_id <> team2_player1_id AND
--         team1_player2_id <> team2_player2_id AND
--         team2_player1_id <> team2_player2_id
--     )
-- );
-- CREATE INDEX idx_trp_round_id ON tournament_round_pairings(round_id);


CREATE TABLE game_results (
    id SERIAL PRIMARY KEY,
    tournament_id INTEGER NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
    round_id INTEGER REFERENCES tournament_rounds(id) ON DELETE SET NULL,
    -- pairing_id INTEGER REFERENCES tournament_round_pairings(id) ON DELETE SET NULL, -- Si usas la tabla de pareos

    -- Jugadores en la partida de dominó (parejas)
    team1_player1_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    team1_player2_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    team2_player1_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    team2_player2_id INTEGER REFERENCES users(id) ON DELETE SET NULL,

    team1_score INT, -- Puntos obtenidos por la pareja 1 en esta partida específica
    team2_score INT, -- Puntos obtenidos por la pareja 2 en esta partida específica

    outcome game_outcome_enum, -- TEAM1_WIN, TEAM2_WIN, DRAW, etc. (puede ser derivado de scores)
    
    game_log TEXT, -- Movimientos/eventos clave de la partida (no PGN, formato libre o JSON)
    game_datetime TIMESTAMPTZ,
    board_number INTEGER,
    reported_by_user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    verified_by_arbiter_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    report_datetime TIMESTAMPTZ,
    verification_datetime TIMESTAMPTZ,

    -- Nivel de ELO que afecta esta partida, determinado por los avales del torneo
    elo_impact_level elo_impact_level_enum DEFAULT 'NONE',

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    -- Para BYE, una pareja podría no tener oponentes
    CONSTRAINT chk_min_players_for_game CHECK (
        (team1_player1_id IS NOT NULL AND team1_player2_id IS NOT NULL) OR outcome = 'BYE'
    ),
    CONSTRAINT chk_game_players_distinct CHECK (
        team1_player1_id IS NULL OR team1_player2_id IS NULL OR team1_player1_id <> team1_player2_id
    ),
    CONSTRAINT chk_game_opponents_distinct_t1p1 CHECK (
        team1_player1_id IS NULL OR team2_player1_id IS NULL OR team1_player1_id <> team2_player1_id
    ),
    CONSTRAINT chk_game_opponents_distinct_t1p2 CHECK (
        team1_player1_id IS NULL OR team2_player2_id IS NULL OR team1_player1_id <> team2_player2_id
    ),
    -- ... agregar más checks para asegurar que los 4 jugadores son distintos si están presentes
    CONSTRAINT chk_all_four_players_distinct CHECK (
        (team1_player1_id IS NULL OR team1_player2_id IS NULL OR team2_player1_id IS NULL OR team2_player2_id IS NULL) OR
        (team1_player1_id <> team1_player2_id AND
         team1_player1_id <> team2_player1_id AND
         team1_player1_id <> team2_player2_id AND
         team1_player2_id <> team2_player1_id AND
         team1_player2_id <> team2_player2_id AND
         team2_player1_id <> team2_player2_id)
    )
);
CREATE INDEX idx_game_results_tournament_id ON game_results(tournament_id);
CREATE INDEX idx_game_results_round_id ON game_results(round_id);
CREATE INDEX idx_game_results_t1p1 ON game_results(team1_player1_id);
CREATE INDEX idx_game_results_t1p2 ON game_results(team1_player2_id);
CREATE INDEX idx_game_results_t2p1 ON game_results(team2_player1_id);
CREATE INDEX idx_game_results_t2p2 ON game_results(team2_player2_id);

-- Tabla para almacenar los cambios de ELO individuales por partida
CREATE TABLE game_player_elo_changes (
    id SERIAL PRIMARY KEY,
    game_id INTEGER NOT NULL REFERENCES game_results(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    previous_elo_official INT,
    new_elo_official INT,
    change_official INT, -- new_elo_official - previous_elo_official
    previous_elo_open INT,
    new_elo_open INT,
    change_open INT, -- new_elo_open - previous_elo_open
    UNIQUE(game_id, user_id) -- Un jugador solo tiene un registro de cambio de ELO por partida
);
CREATE INDEX idx_gpec_user_id ON game_player_elo_changes(user_id);


CREATE TABLE elo_history (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    game_id INTEGER REFERENCES game_results(id) ON DELETE SET NULL, -- Enlace a la partida que causó el cambio
    -- Opcional: game_player_elo_change_id INTEGER REFERENCES game_player_elo_changes(id) ON DELETE SET NULL,
    elo_type VARCHAR(10) NOT NULL, -- 'OFFICIAL' o 'OPEN'
    previous_elo INT,
    new_elo INT,
    change_amount INT, -- new_elo - previous_elo
    change_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    reason TEXT -- e.g., 'Tournament Game', 'Initial Rating', 'Manual Adjustment', 'Endorsement Adjustment'
);
CREATE INDEX idx_elo_history_user_id ON elo_history(user_id);
CREATE INDEX idx_elo_history_game_id ON elo_history(game_id);


CREATE TABLE published_rankings (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    category ranking_category_enum NOT NULL,
    -- Si es un ranking de una organización específica (Club, Asociación, Federación)
    organization_id INTEGER REFERENCES organizations(id) ON DELETE CASCADE,
    -- Para rankings UNIVERSAL_FID o CONTINENTAL_FID, organization_id puede ser el ID de FIDE o NULL/específico.
    -- Para rankings NATIONAL_FEDERATION, organization_id es el ID de la Federación.
    -- Para rankings REGIONAL_ASSOCIATION, organization_id es el ID de la Asociación.
    -- Para rankings LOCAL_CLUB, organization_id es el ID del Club.
    country_code_filter CHAR(2), -- Para filtrar rankings nacionales/regionales dentro de una categoría más amplia
    region_filter VARCHAR(100),  -- Para filtrar rankings de asociación/provincia
    effective_date DATE NOT NULL,
    published_by_user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    publication_datetime TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (category, organization_id, effective_date) -- Evitar duplicados del mismo ranking para la misma fecha
);
CREATE INDEX idx_published_rankings_category ON published_rankings(category);
CREATE INDEX idx_published_rankings_organization_id ON published_rankings(organization_id);
CREATE INDEX idx_published_rankings_effective_date ON published_rankings(effective_date);

CREATE TABLE ranking_entries (
    id SERIAL PRIMARY KEY,
    published_ranking_id INTEGER NOT NULL REFERENCES published_rankings(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    rank_position INTEGER NOT NULL,
    elo_at_publication INT NOT NULL,
    games_played_in_period INT,
    UNIQUE (published_ranking_id, user_id),
    UNIQUE (published_ranking_id, rank_position)
);
CREATE INDEX idx_ranking_entries_user_id ON ranking_entries(user_id);

-- Tabla para eventos publicados por usuarios/organizaciones con licencia premium
CREATE TABLE published_events (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    event_start_datetime TIMESTAMPTZ NOT NULL,
    event_end_datetime TIMESTAMPTZ,
    location_details TEXT,
    cost_per_participant NUMERIC(10,2),
    prize_information TEXT,
    -- Quién publica el evento (puede ser un usuario individual o una organización)
    organizer_user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    organizer_organization_id INTEGER REFERENCES organizations(id) ON DELETE SET NULL,
    contact_info TEXT,
    event_website_url TEXT,
    banner_image_url TEXT,
    published_by_user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE RESTRICT, -- Usuario que creó la entrada
    published_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    is_public BOOLEAN DEFAULT TRUE, -- Si es visible en el calendario público
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_event_organizer CHECK ( (organizer_user_id IS NOT NULL AND organizer_organization_id IS NULL) OR (organizer_user_id IS NULL AND organizer_organization_id IS NOT NULL) )
);
CREATE INDEX idx_published_events_organizer_user_id ON published_events(organizer_user_id);
CREATE INDEX idx_published_events_organizer_org_id ON published_events(organizer_organization_id);
CREATE INDEX idx_published_events_start_datetime ON published_events(event_start_datetime);


-- DATOS INICIALES (EJEMPLOS)
INSERT INTO roles (name, description) VALUES
('SUPER_ADMIN', 'Administrador global del sistema'),
('FID_ADMIN', 'Administrador de la FID'),
('MODERATOR_FID', 'Moderador autorizado por la FID para verificaciones de org/identidad'),
('FEDERATION_ADMIN', 'Administrador de una Federación Nacional'),
('ASSOCIATION_ADMIN', 'Administrador de una Asociación Estatal/Provincial'),
('CLUB_ADMIN', 'Administrador de un Club'),
('LICENSED_ORGANIZER', 'Usuario con licencia para organizar torneos/eventos'),
('PLAYER', 'Jugador registrado'),
('ARBITER', 'Árbitro registrado'),
('AFICIONADO', 'Usuario aficionado general');

INSERT INTO license_types (name, description, price_monthly, price_annual, features, max_concurrent_sessions, is_available) VALUES
('BASICA_AFICIONADO', 'Acceso a participar y ver rankings.', 5.00, 50.00,
 '{ "max_concurrent_tournaments_organized": 0, "can_publish_events": false, "tournament_participation": true }',
 1, TRUE),
('BASICA_ORGANIZADOR', 'Organiza 1 torneo a la vez, ranking abierto.', 20.00, 200.00,
 '{ "max_concurrent_tournaments_organized": 1, "max_participants_per_tournament": 64, "modalities_allowed": ["Suizo", "Patio"], "ranking_types_affected": ["OPEN_AMATEUR"], "can_publish_events": false, "support": "email" }',
 1, TRUE),
('PREMIUM_ORGANIZADOR', 'Múltiples torneos, todas las modalidades, solicitud de avales, publicación de eventos.', 50.00, 500.00,
 '{ "max_concurrent_tournaments_organized": null, "max_participants_per_tournament": null, "modalities_allowed": ["ALL"], "ranking_types_affected": ["OPEN_AMATEUR", "OFFICIAL_VIA_ENDORSEMENT"], "can_publish_events": true, "can_request_endorsement": true, "detailed_stats_access": true, "support": "priority_email_phone", "custom_branding": true }',
 5, TRUE);

INSERT INTO tournament_modalities (name, description, requires_pairing_algorithm, min_players_per_game, max_players_per_game) VALUES
('Sistema Suizo Parejas', 'Sistema Suizo adaptado para parejas rotativas.', TRUE, 4, 4),
('Round Robin Parejas (Liguilla)', 'Todos contra todos en formato de parejas.', TRUE, 4, 4),
('Eliminatoria Directa Parejas (Llave)', 'Torneo de eliminación para parejas.', TRUE, 4, 4),
('Juego Libre (Patio)', 'Formato informal, los jugadores organizan sus partidas.', FALSE, 2, 4), -- Flexible
('Ciclos Fijos por Rondas', 'Cada ronda se juega a un número determinado de ciclos (4 manos por ciclo).', TRUE, 4, 4);

-- Ejemplo de usuario y organización FID (asumiendo que el primer usuario es SUPER_ADMIN y crea FIDE)
-- INSERT INTO users (email, password_hash, first_name, last_name, is_verified_identity, country_code) VALUES
-- ('super@admin.org', 'hashed_password', 'Super', 'Admin', TRUE, 'CH');
-- INSERT INTO user_roles (user_id, role_id) VALUES (1, (SELECT id FROM roles WHERE name='SUPER_ADMIN'));

-- INSERT INTO organizations (name, type, country_code, is_officially_verified, verification_date, verified_by_user_id)
-- VALUES ('Fédération Internationale de Domino (FID)', 'FID', 'CH', TRUE, CURRENT_TIMESTAMP, 1);
-- UPDATE users SET fid_id = 'FID00001' WHERE id=1;
-- INSERT INTO organization_staff (user_id, organization_id, role_in_organization, can_manage_endorsements, can_approve_children_orgs)
-- VALUES (1, 1, 'Presidente Interino FID', TRUE, TRUE);
