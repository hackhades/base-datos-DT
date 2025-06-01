-- Eliminar tablas existentes si es necesario (para desarrollo)
-- Considerar el orden por las dependencias de FK
DROP TABLE IF EXISTS game_results CASCADE;
DROP TABLE IF EXISTS tournament_rounds CASCADE;
DROP TABLE IF EXISTS tournament_participants CASCADE;
DROP TABLE IF EXISTS tournament_arbiters CASCADE;
DROP TABLE IF EXISTS tournaments CASCADE;
DROP TABLE IF EXISTS ranking_entries CASCADE;
DROP TABLE IF EXISTS published_rankings CASCADE;
DROP TABLE IF EXISTS elo_history CASCADE;
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
DROP TYPE IF EXISTS game_result_enum CASCADE;
DROP TYPE IF EXISTS ranking_category_enum CASCADE;
DROP TYPE IF EXISTS verification_status_enum CASCADE;

-- TIPOS ENUMERADOS
CREATE TYPE organization_type_enum AS ENUM ('FID', 'FEDERATION', 'ASSOCIATION', 'CLUB');
CREATE TYPE license_status_enum AS ENUM ('ACTIVE', 'INACTIVE', 'PENDING_PAYMENT', 'EXPIRED', 'CANCELLED');
CREATE TYPE payment_interval_enum AS ENUM ('MONTHLY', 'ANNUAL');
CREATE TYPE tournament_status_enum AS ENUM ('PLANNED', 'REGISTRATION_OPEN', 'REGISTRATION_CLOSED', 'ONGOING', 'COMPLETED', 'CANCELLED');
CREATE TYPE game_result_enum AS ENUM ('1-0', '0-1', '1/2-1/2', 'FORFEIT_WIN_WHITE', 'FORFEIT_WIN_BLACK', 'PENDING', 'BYE');
CREATE TYPE ranking_category_enum AS ENUM ('OFFICIAL_UNIVERSAL', 'OFFICIAL_FEDERATION', 'OFFICIAL_ASSOCIATION', 'OFFICIAL_CLUB', 'OPEN_AMATEUR');
CREATE TYPE verification_status_enum AS ENUM ('PENDING', 'APPROVED', 'REJECTED', 'NEEDS_INFO');

-- TABLAS EXISTENTES (MODIFICADAS/AMPLIADAS LEVEMENTE DEL EJEMPLO)
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    date_of_birth DATE,
    fid_id VARCHAR(50) UNIQUE, -- ID FIDE del jugador/árbitro si aplica
    profile_picture_url TEXT,
    official_elo INT DEFAULT 1200, -- ELO para rankings oficiales
    open_elo INT DEFAULT 1200,     -- ELO para rankings abiertos
    is_verified_identity BOOLEAN DEFAULT FALSE, -- Para moderadores FID, árbitros, etc.
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE sessions (
    id UUID PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    expires_at TIMESTAMPTZ NOT NULL,
    ip_address VARCHAR(45), -- Para control de sesiones
    user_agent TEXT,       -- Para control de sesiones
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_sessions_user_id ON sessions(user_id);

-- NUEVAS TABLAS
CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL, -- e.g., 'FID_ADMIN', 'FEDERATION_ADMIN', 'CLUB_ADMIN', 'PLAYER', 'ARBITER', 'AFICIONADO', 'MODERATOR_FID'
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
    parent_organization_id INTEGER REFERENCES organizations(id) ON DELETE SET NULL, -- FID no tiene padre, Federacion puede tener FID como padre simbólico (o null), etc.
    country_code CHAR(2), -- ISO 3166-1 alpha-2 (ej. 'ES', 'US')
    region_or_state VARCHAR(100), -- Provincia, estado, departamento
    city VARCHAR(100),
    address TEXT,
    contact_email VARCHAR(255),
    contact_phone VARCHAR(50),
    website_url TEXT,
    logo_url TEXT,
    founded_date DATE,
    description TEXT,
    is_officially_verified BOOLEAN DEFAULT FALSE,
    verified_by_organization_id INTEGER REFERENCES organizations(id) ON DELETE SET NULL, -- Quién lo verificó (ej. una Federación verifica una Asociación)
    verified_by_user_id INTEGER REFERENCES users(id) ON DELETE SET NULL, -- Qué usuario específico (admin de la org padre) lo verificó
    verification_date TIMESTAMPTZ,
    verification_document_url TEXT, -- Para la solicitud inicial
    social_media_link_for_verification TEXT, -- Para la solicitud inicial
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (name, type, parent_organization_id) -- Evitar duplicados de mismo nombre y tipo bajo el mismo padre
);
CREATE INDEX idx_organizations_type ON organizations(type);
CREATE INDEX idx_organizations_parent_id ON organizations(parent_organization_id);
CREATE INDEX idx_organizations_country_code ON organizations(country_code);

-- Tabla para registrar solicitudes de verificación (historial y estado)
CREATE TABLE organization_verification_requests (
    id SERIAL PRIMARY KEY,
    requesting_organization_id INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    approving_organization_id INTEGER REFERENCES organizations(id) ON DELETE SET NULL, -- La organización que debe aprobar (FID, Federación, Asociación)
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


-- Usuarios que son staff/administradores de organizaciones
CREATE TABLE organization_staff (
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    organization_id INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    role_in_organization VARCHAR(100), -- e.g., 'Presidente', 'Secretario', 'Admin Sistema'
    is_primary_contact BOOLEAN DEFAULT FALSE,
    can_manage_licenses BOOLEAN DEFAULT FALSE,
    can_manage_tournaments BOOLEAN DEFAULT FALSE,
    can_approve_children BOOLEAN DEFAULT FALSE, -- Si puede aprobar orgs hijas (ej. Fed admin aprueba Asociaciones)
    added_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, organization_id)
);
CREATE INDEX idx_organization_staff_organization_id ON organization_staff(organization_id);


CREATE TABLE license_types (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL, -- 'BASICA', 'PREMIUM'
    description TEXT,
    price_monthly NUMERIC(10,2) NOT NULL,
    price_annual NUMERIC(10,2) NOT NULL,
    features JSONB, -- { "max_tournaments": 5, "elo_type": "basic", "detailed_stats": false, "allow_multiple_sessions": false }
    max_concurrent_sessions INT DEFAULT 1, -- 1 para básica, >1 o NULL (ilimitado) para premium
    is_available BOOLEAN DEFAULT TRUE
);

CREATE TABLE licenses (
    id SERIAL PRIMARY KEY,
    license_type_id INTEGER NOT NULL REFERENCES license_types(id) ON DELETE RESTRICT,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE, -- Para licencias de aficionados
    organization_id INTEGER REFERENCES organizations(id) ON DELETE CASCADE, -- Para licencias de organizaciones
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ NOT NULL,
    payment_interval payment_interval_enum NOT NULL,
    status license_status_enum NOT NULL DEFAULT 'PENDING_PAYMENT',
    auto_renew BOOLEAN DEFAULT FALSE,
    transaction_id VARCHAR(255), -- Referencia a la pasarela de pago
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_license_owner CHECK ( (user_id IS NOT NULL AND organization_id IS NULL) OR (user_id IS NULL AND organization_id IS NOT NULL) )
);
CREATE INDEX idx_licenses_user_id ON licenses(user_id);
CREATE INDEX idx_licenses_organization_id ON licenses(organization_id);
CREATE INDEX idx_licenses_end_date ON licenses(end_date);


CREATE TABLE elo_history (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    game_id INTEGER, -- FK a games, se añadirá más adelante. Nullable para ajustes manuales.
    previous_official_elo INT,
    new_official_elo INT,
    previous_open_elo INT,
    new_open_elo INT,
    change_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    reason TEXT -- e.g., 'Tournament Game', 'Initial Rating', 'Manual Adjustment'
);
CREATE INDEX idx_elo_history_user_id ON elo_history(user_id);


CREATE TABLE tournaments (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    -- Organizador: puede ser una organización o un aficionado (usuario)
    organizer_organization_id INTEGER REFERENCES organizations(id) ON DELETE SET NULL,
    organizer_user_id INTEGER REFERENCES users(id) ON DELETE SET NULL, -- Para torneos de aficionados
    modality VARCHAR(100) NOT NULL, -- e.g., 'Sistema Suizo', 'Round Robin', 'Eliminatoria' (podría ser FK a una tabla tournament_modalities)
    start_datetime TIMESTAMPTZ NOT NULL,
    end_datetime TIMESTAMPTZ,
    location_venue_name VARCHAR(255),
    location_address TEXT,
    location_city VARCHAR(100),
    location_country_code CHAR(2),
    is_official BOOLEAN NOT NULL, -- True si es avalado y afecta ranking oficial, False para ranking abierto
    status tournament_status_enum DEFAULT 'PLANNED',
    max_participants INTEGER,
    registration_deadline TIMESTAMPTZ,
    entry_fee NUMERIC(8,2) DEFAULT 0.00,
    rules_details TEXT, -- o URL a un PDF de reglas
    prize_details TEXT,
    banner_image_url TEXT,
    created_by_user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE RESTRICT, -- Quién creó el registro en el sistema
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_tournament_organizer CHECK ( (organizer_organization_id IS NOT NULL AND organizer_user_id IS NULL) OR (organizer_organization_id IS NULL AND organizer_user_id IS NOT NULL) )
);
CREATE INDEX idx_tournaments_organizer_organization_id ON tournaments(organizer_organization_id);
CREATE INDEX idx_tournaments_organizer_user_id ON tournaments(organizer_user_id);
CREATE INDEX idx_tournaments_status ON tournaments(status);
CREATE INDEX idx_tournaments_is_official ON tournaments(is_official);


CREATE TABLE tournament_participants (
    id SERIAL PRIMARY KEY,
    tournament_id INTEGER NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE, -- El jugador participante
    registration_datetime TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    initial_rating_official INT, -- ELO oficial al momento de la inscripción
    initial_rating_open INT,     -- ELO abierto al momento de la inscripción
    final_ranking_position INTEGER,
    points_achieved NUMERIC(4,1), -- e.g. 7.5 puntos
    tie_break_score1 NUMERIC(10,2), -- Buchholz, etc.
    tie_break_score2 NUMERIC(10,2), -- Sonneborn-Berger, etc.
    is_confirmed BOOLEAN DEFAULT FALSE,
    payment_status VARCHAR(50) DEFAULT 'NOT_APPLICABLE', -- 'PAID', 'PENDING', 'WAIVED'
    UNIQUE (tournament_id, user_id)
);
CREATE INDEX idx_tournament_participants_user_id ON tournament_participants(user_id);

CREATE TABLE tournament_arbiters (
    tournament_id INTEGER NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE, -- El árbitro
    role_in_tournament VARCHAR(100) DEFAULT 'Arbiter', -- 'Chief Arbiter', 'Deputy Arbiter', 'Arbiter'
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
    UNIQUE (tournament_id, round_number)
);

CREATE TABLE game_results (
    id SERIAL PRIMARY KEY,
    tournament_id INTEGER NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
    round_id INTEGER REFERENCES tournament_rounds(id) ON DELETE SET NULL, -- Puede ser null si no es por rondas o es un match suelto
    player_white_id INTEGER REFERENCES users(id) ON DELETE SET NULL, -- Jugador con blancas
    player_black_id INTEGER REFERENCES users(id) ON DELETE SET NULL, -- Jugador con negras
    result game_result_enum,
    pgn_moves TEXT, -- Movimientos en formato PGN
    game_datetime TIMESTAMPTZ,
    board_number INTEGER,
    reported_by_user_id INTEGER REFERENCES users(id) ON DELETE SET NULL, -- Quién reportó (árbitro, jugador)
    verified_by_arbiter_id INTEGER REFERENCES users(id) ON DELETE SET NULL, -- Árbitro que verificó
    report_datetime TIMESTAMPTZ,
    verification_datetime TIMESTAMPTZ,
    elo_change_white_official INT,
    elo_change_black_official INT,
    elo_change_white_open INT,
    elo_change_black_open INT,
    affects_official_elo BOOLEAN, -- Determinado por el torneo
    affects_open_elo BOOLEAN,     -- Determinado por el torneo
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_players_not_same CHECK (player_white_id IS NULL OR player_black_id IS NULL OR player_white_id <> player_black_id),
    CONSTRAINT chk_at_least_one_player CHECK (player_white_id IS NOT NULL OR player_black_id IS NOT NULL) -- Para BYEs
);
CREATE INDEX idx_game_results_tournament_id ON game_results(tournament_id);
CREATE INDEX idx_game_results_round_id ON game_results(round_id);
CREATE INDEX idx_game_results_player_white_id ON game_results(player_white_id);
CREATE INDEX idx_game_results_player_black_id ON game_results(player_black_id);

-- Añadir FK de elo_history a game_results ahora que game_results existe
ALTER TABLE elo_history
ADD CONSTRAINT fk_elo_history_game
FOREIGN KEY (game_id) REFERENCES game_results(id) ON DELETE SET NULL;


-- Tabla para rankings publicados (snapshots)
CREATE TABLE published_rankings (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL, -- e.g., "Ranking Oficial FIDE Mayo 2024", "Ranking Abierto Club XYZ Primavera"
    category ranking_category_enum NOT NULL,
    organization_id INTEGER REFERENCES organizations(id) ON DELETE CASCADE, -- Para rankings de Club, Asociación, Federación
    effective_date DATE NOT NULL, -- Fecha para la cual el ranking es válido
    published_by_user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    publication_datetime TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE, -- Si es el último ranking publicado de su categoría/organización
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_published_rankings_category ON published_rankings(category);
CREATE INDEX idx_published_rankings_organization_id ON published_rankings(organization_id);
CREATE INDEX idx_published_rankings_effective_date ON published_rankings(effective_date);


-- Entradas específicas de un ranking publicado
CREATE TABLE ranking_entries (
    id SERIAL PRIMARY KEY,
    published_ranking_id INTEGER NOT NULL REFERENCES published_rankings(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE, -- El jugador
    rank_position INTEGER NOT NULL,
    elo_at_publication INT NOT NULL,
    games_played_in_period INT, -- Opcional, cuántas partidas contaron para este ranking
    UNIQUE (published_ranking_id, user_id),
    UNIQUE (published_ranking_id, rank_position) -- No dos jugadores en la misma posición en el mismo ranking
);
CREATE INDEX idx_ranking_entries_user_id ON ranking_entries(user_id);


-- DATOS INICIALES (EJEMPLOS)
INSERT INTO roles (name, description) VALUES
('SUPER_ADMIN', 'Administrador global del sistema'),
('FID_ADMIN', 'Administrador de la FID'),
('MODERATOR_FID', 'Moderador autorizado por la FID para verificaciones'),
('FEDERATION_ADMIN', 'Administrador de una Federación Nacional'),
('ASSOCIATION_ADMIN', 'Administrador de una Asociación Estatal/Provincial'),
('CLUB_ADMIN', 'Administrador de un Club'),
('PLAYER', 'Jugador registrado'),
('ARBITER', 'Árbitro registrado'),
('AFICIONADO', 'Usuario aficionado con o sin licencia');

INSERT INTO license_types (name, description, price_monthly, price_annual, features, max_concurrent_sessions, is_available) VALUES
('BASICA', 'Funciones esenciales para torneos y ranking.', 20.00, 200.00,
 '{ "max_tournaments_active": 3, "max_participants_per_tournament": 64, "modalities": ["Suizo"], "ranking_type": "open", "detailed_stats": false, "support": "email" }',
 1, TRUE),
('PREMIUM', 'Todas las funciones, modalidades avanzadas y estadísticas detalladas.', 50.00, 500.00,
 '{ "max_tournaments_active": null, "max_participants_per_tournament": null, "modalities": ["Suizo", "Round Robin", "Eliminatoria", "Scheveningen"], "ranking_type": "official_and_open", "detailed_stats": true, "support": "priority_email_phone", "custom_branding": true }',
 5, TRUE); -- max_concurrent_sessions > 1 o NULL para ilimitado

-- Ejemplo de usuario (necesitarás hashear la contraseña)
-- INSERT INTO users (email, password_hash, first_name, last_name) VALUES ('admin@example.com', 'hashed_password_here', 'Admin', 'Principal');
-- INSERT INTO user_roles (user_id, role_id) VALUES ( (SELECT id FROM users WHERE email='admin@example.com'), (SELECT id FROM roles WHERE name='SUPER_ADMIN') );

-- Ejemplo de organización FID (la única de tipo FID)
-- INSERT INTO organizations (name, type, is_officially_verified, verification_date)
-- VALUES ('Fédération Internationale des Échecs (FIDE)', 'FID', TRUE, CURRENT_TIMESTAMP);