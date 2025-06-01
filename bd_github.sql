-- Tabla de países (para federaciones nacionales)
CREATE TABLE country (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    iso_code CHAR(3) UNIQUE
);

-- Tabla de organizaciones
CREATE TABLE federation (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    country_id INTEGER REFERENCES country(id),
    is_verified BOOLEAN DEFAULT FALSE,
    verified_by INTEGER REFERENCES user_account(id), -- quien verifica (FID)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    verified_at TIMESTAMP
);

CREATE TABLE association (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    federation_id INTEGER REFERENCES federation(id),
    state VARCHAR(100),
    is_verified BOOLEAN DEFAULT FALSE,
    verified_by INTEGER REFERENCES user_account(id), -- quien verifica (federación)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    verified_at TIMESTAMP
);

CREATE TABLE club (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    association_id INTEGER REFERENCES association(id),
    is_verified BOOLEAN DEFAULT FALSE,
    verified_by INTEGER REFERENCES user_account(id), -- quien verifica (asociación)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    verified_at TIMESTAMP
);

-- Tipos de usuario (puede usarse como rol: admin, árbitro, jugador, aficionado, FID, moderador)
CREATE TABLE user_role (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE -- 'fid', 'federation_admin', 'association_admin', 'club_admin', 'moderator', 'player', 'referee', 'fan'
);

-- Usuarios y relación con organizaciones
-- NOTA: Asumo que el repo base tiene tabla de usuarios llamada user_account, si no, renómbrala según corresponda
ALTER TABLE user_account
    ADD COLUMN role_id INTEGER REFERENCES user_role(id),
    ADD COLUMN federation_id INTEGER REFERENCES federation(id),
    ADD COLUMN association_id INTEGER REFERENCES association(id),
    ADD COLUMN club_id INTEGER REFERENCES club(id),
    ADD COLUMN is_verified BOOLEAN DEFAULT FALSE,
    ADD COLUMN verified_by INTEGER REFERENCES user_account(id),
    ADD COLUMN document_url TEXT, -- para documento de verificación
    ADD COLUMN social_profile_url TEXT;

-- Licencias
CREATE TABLE license_type (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE, -- 'basic', 'premium'
    description TEXT,
    allows_multiple_sessions BOOLEAN DEFAULT FALSE,
    price_monthly NUMERIC(10,2),
    price_yearly NUMERIC(10,2)
);

CREATE TABLE license (
    id SERIAL PRIMARY KEY,
    license_type_id INTEGER REFERENCES license_type(id),
    user_id INTEGER REFERENCES user_account(id),
    org_type VARCHAR(20), -- 'federation', 'association', 'club', 'fan'
    org_id INTEGER, -- id de la organización
    start_date DATE DEFAULT CURRENT_DATE,
    end_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    auto_renew BOOLEAN DEFAULT FALSE
);

-- Sesiones abiertas por usuario (para limitar sesiones)
CREATE TABLE user_session (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES user_account(id),
    session_token VARCHAR(255) UNIQUE,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMP
);

-- Árbitros (pueden ser usuarios con rol específico, pero separamos detalles)
CREATE TABLE referee (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES user_account(id),
    certified_by INTEGER REFERENCES user_account(id), -- quién lo avaló
    certification_document TEXT,
    is_verified BOOLEAN DEFAULT FALSE,
    verified_at TIMESTAMP
);

-- Jugadores (pueden ser usuarios con rol específico, separamos detalles)
CREATE TABLE player (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES user_account(id),
    federation_id INTEGER REFERENCES federation(id),
    association_id INTEGER REFERENCES association(id),
    club_id INTEGER REFERENCES club(id),
    elo_rating NUMERIC(6,2) DEFAULT 1200.00
);

-- Torneos
CREATE TABLE tournament (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    organizer_type VARCHAR(20), -- 'federation', 'association', 'club', 'fan'
    organizer_id INTEGER,
    start_date DATE,
    end_date DATE,
    system VARCHAR(50), -- 'swiss', 'round_robin', etc
    is_official BOOLEAN DEFAULT FALSE,
    created_by INTEGER REFERENCES user_account(id)
);

-- Partidas
CREATE TABLE match (
    id SERIAL PRIMARY KEY,
    tournament_id INTEGER REFERENCES tournament(id),
    round INTEGER,
    player1_id INTEGER REFERENCES player(id),
    player2_id INTEGER REFERENCES player(id),
    result VARCHAR(20), -- '1-0', '0-1', '0.5-0.5', etc
    played_at TIMESTAMP
);

-- Ranking ELO y publicación de rankings
CREATE TABLE ranking (
    id SERIAL PRIMARY KEY,
    player_id INTEGER REFERENCES player(id),
    elo NUMERIC(6,2),
    date DATE DEFAULT CURRENT_DATE,
    is_official BOOLEAN DEFAULT FALSE
);

-- Historial de publicaciones de ranking (para saber quién publica y qué tipo)
CREATE TABLE ranking_publication (
    id SERIAL PRIMARY KEY,
    ranking_id INTEGER REFERENCES ranking(id),
    published_by INTEGER REFERENCES user_account(id),
    published_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_official BOOLEAN DEFAULT FALSE
);

-- Historial de pagos de licencias
CREATE TABLE license_payment (
    id SERIAL PRIMARY KEY,
    license_id INTEGER REFERENCES license(id),
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    amount NUMERIC(10,2),
    payment_method VARCHAR(50), -- 'credit_card', 'paypal', etc.
    is_annual BOOLEAN DEFAULT FALSE,
    discount_applied NUMERIC(5,2) DEFAULT 0
);

-- Opcional: logs de acciones administrativas
CREATE TABLE admin_action_log (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES user_account(id),
    action VARCHAR(100),
    target_type VARCHAR(50),
    target_id INTEGER,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    details TEXT
);