-- =====================================================
-- SISTEMA DE DOMINÓ PROFESIONAL - ESQUEMA COMPLETO
-- =====================================================

-- Tabla de usuarios base (ya existe en el repositorio, pero extendida)
DROP TABLE IF EXISTS users CASCADE;
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    country VARCHAR(100),
    city VARCHAR(100),
    birth_date DATE,
    profile_image VARCHAR(500),
    is_active BOOLEAN DEFAULT true,
    email_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tipos de licencias
DROP TABLE IF EXISTS license_types CASCADE;
CREATE TABLE license_types (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL, -- 'basica', 'premium'
    description TEXT,
    monthly_price DECIMAL(10,2) NOT NULL,
    annual_price DECIMAL(10,2) NOT NULL,
    max_simultaneous_sessions INTEGER DEFAULT 1,
    features JSONB, -- Características específicas de cada licencia
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Licencias de usuarios
DROP TABLE IF EXISTS user_licenses CASCADE;
CREATE TABLE user_licenses (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    license_type_id INTEGER REFERENCES license_types(id),
    payment_type VARCHAR(20) NOT NULL CHECK (payment_type IN ('monthly', 'annual')),
    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP NOT NULL,
    is_active BOOLEAN DEFAULT true,
    auto_renew BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sesiones activas (para control de sesiones únicas en licencia básica)
DROP TABLE IF EXISTS active_sessions CASCADE;
CREATE TABLE active_sessions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    session_token VARCHAR(255) UNIQUE NOT NULL,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_activity TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);

-- Tipos de organizaciones
DROP TABLE IF EXISTS organization_types CASCADE;
CREATE TABLE organization_types (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL, -- 'FID', 'federation', 'association', 'club'
    description TEXT,
    hierarchy_level INTEGER NOT NULL, -- 1=FID, 2=Federation, 3=Association, 4=Club
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Organizaciones (FID, Federaciones, Asociaciones, Clubes)
DROP TABLE IF EXISTS organizations CASCADE;
CREATE TABLE organizations (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    short_name VARCHAR(50),
    organization_type_id INTEGER REFERENCES organization_types(id),
    parent_organization_id INTEGER REFERENCES organizations(id),
    country VARCHAR(100),
    state_province VARCHAR(100),
    city VARCHAR(100),
    address TEXT,
    phone VARCHAR(20),
    email VARCHAR(255),
    website VARCHAR(300),
    logo_url VARCHAR(500),
    description TEXT,
    verification_document VARCHAR(500), -- URL del documento de verificación
    social_media_links JSONB, -- Enlaces a redes sociales para verificación
    is_verified BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    verification_date TIMESTAMP,
    verified_by INTEGER REFERENCES users(id), -- Quién verificó la organización
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Roles de usuarios en organizaciones
DROP TABLE IF EXISTS user_roles CASCADE;
CREATE TABLE user_roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL, -- 'admin', 'moderator', 'player', 'referee', 'fan'
    description TEXT,
    permissions JSONB, -- Permisos específicos del rol
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Relación usuarios con organizaciones y roles
DROP TABLE IF EXISTS user_organization_roles CASCADE;
CREATE TABLE user_organization_roles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    organization_id INTEGER REFERENCES organizations(id) ON DELETE CASCADE,
    role_id INTEGER REFERENCES user_roles(id),
    is_verified BOOLEAN DEFAULT false, -- Si el rol está verificado por la organización
    verification_document VARCHAR(500), -- Documento que respalda el rol
    verified_by INTEGER REFERENCES users(id), -- Quién verificó el rol
    verification_date TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, organization_id, role_id)
);

-- Jugadores (perfil específico para dominó)
DROP TABLE IF EXISTS players CASCADE;
CREATE TABLE players (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    player_number VARCHAR(50), -- Número de jugador oficial
    elo_rating_official INTEGER DEFAULT 1200, -- Rating ELO oficial
    elo_rating_open INTEGER DEFAULT 1200, -- Rating ELO abierto
    games_played_official INTEGER DEFAULT 0,
    games_played_open INTEGER DEFAULT 0,
    wins_official INTEGER DEFAULT 0,
    wins_open INTEGER DEFAULT 0,
    losses_official INTEGER DEFAULT 0,
    losses_open INTEGER DEFAULT 0,
    draws_official INTEGER DEFAULT 0,
    draws_open INTEGER DEFAULT 0,
    best_rating_official INTEGER DEFAULT 1200,
    best_rating_open INTEGER DEFAULT 1200,
    current_streak INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    preferred_partner INTEGER REFERENCES players(id), -- Compañero preferido
    is_seeking_partner BOOLEAN DEFAULT false,
    playing_style TEXT,
    achievements JSONB, -- Logros y medallas
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Árbitros
DROP TABLE IF EXISTS referees CASCADE;
CREATE TABLE referees (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    referee_number VARCHAR(50),
    certification_level VARCHAR(50), -- 'nacional', 'internacional', etc.
    certification_date DATE,
    certification_expires DATE,
    certifying_organization_id INTEGER REFERENCES organizations(id),
    languages JSONB, -- Idiomas que maneja
    specializations JSONB, -- Especializaciones (modalidades de juego)
    tournaments_officiated INTEGER DEFAULT 0,
    rating DECIMAL(3,2) DEFAULT 5.00, -- Rating del árbitro (1-5)
    is_active BOOLEAN DEFAULT true,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Modalidades de juego
DROP TABLE IF EXISTS game_modes CASCADE;
CREATE TABLE game_modes (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL, -- 'sistema_suizo', 'eliminacion_directa', etc.
    description TEXT,
    min_players INTEGER NOT NULL,
    max_players INTEGER,
    is_team_mode BOOLEAN DEFAULT true, -- Si es por parejas
    scoring_system JSONB, -- Sistema de puntuación específico
    rules JSONB, -- Reglas específicas de la modalidad
    license_required VARCHAR(20) DEFAULT 'basica', -- 'basica' o 'premium'
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Torneos
DROP TABLE IF EXISTS tournaments CASCADE;
CREATE TABLE tournaments (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    organizing_entity_id INTEGER REFERENCES organizations(id),
    organized_by INTEGER REFERENCES users(id), -- Usuario que organiza
    game_mode_id INTEGER REFERENCES game_modes(id),
    tournament_type VARCHAR(20) NOT NULL CHECK (tournament_type IN ('official', 'open')),
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'registration', 'ongoing', 'finished', 'cancelled')),
    registration_start TIMESTAMP,
    registration_end TIMESTAMP,
    start_date TIMESTAMP,
    end_date TIMESTAMP,
    venue_name VARCHAR(200),
    venue_address TEXT,
    city VARCHAR(100),
    country VARCHAR(100),
    max_participants INTEGER,
    entry_fee DECIMAL(10,2) DEFAULT 0,
    prize_pool DECIMAL(10,2) DEFAULT 0,
    prize_distribution JSONB, -- Distribución de premios
    registration_requirements JSONB, -- Requisitos para inscripción
    rules JSONB, -- Reglas específicas del torneo
    contact_info JSONB, -- Información de contacto
    poster_url VARCHAR(500),
    live_streaming_url VARCHAR(500),
    is_rated BOOLEAN DEFAULT true, -- Si afecta el rating ELO
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Inscripciones a torneos
DROP TABLE IF EXISTS tournament_registrations CASCADE;
CREATE TABLE tournament_registrations (
    id SERIAL PRIMARY KEY,
    tournament_id INTEGER REFERENCES tournaments(id) ON DELETE CASCADE,
    player1_id INTEGER REFERENCES players(id),
    player2_id INTEGER REFERENCES players(id),
    team_name VARCHAR(100),
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'cancelled')),
    payment_status VARCHAR(20) DEFAULT 'unpaid' CHECK (payment_status IN ('unpaid', 'paid', 'refunded')),
    payment_date TIMESTAMP,
    payment_reference VARCHAR(100),
    notes TEXT,
    seeding_number INTEGER, -- Número de cabeza de serie
    UNIQUE(tournament_id, player1_id, player2_id)
);

-- Rondas de torneos
DROP TABLE IF EXISTS tournament_rounds CASCADE;
CREATE TABLE tournament_rounds (
    id SERIAL PRIMARY KEY,
    tournament_id INTEGER REFERENCES tournaments(id) ON DELETE CASCADE,
    round_number INTEGER NOT NULL,
    round_name VARCHAR(100), -- 'Ronda 1', 'Cuartos de Final', etc.
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'ongoing', 'finished')),
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Partidas
DROP TABLE IF EXISTS matches CASCADE;
CREATE TABLE matches (
    id SERIAL PRIMARY KEY,
    tournament_id INTEGER REFERENCES tournaments(id),
    round_id INTEGER REFERENCES tournament_rounds(id),
    match_number INTEGER,
    table_number INTEGER,
    team1_player1_id INTEGER REFERENCES players(id),
    team1_player2_id INTEGER REFERENCES players(id),
    team2_player1_id INTEGER REFERENCES players(id),
    team2_player2_id INTEGER REFERENCES players(id),
    referee_id INTEGER REFERENCES referees(id),
    status VARCHAR(20) DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'ongoing', 'finished', 'cancelled')),
    scheduled_time TIMESTAMP,
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    team1_score INTEGER DEFAULT 0,
    team2_score INTEGER DEFAULT 0,
    winner_team INTEGER CHECK (winner_team IN (1, 2)), -- 1 o 2
    games_detail JSONB, -- Detalle de cada juego
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Juegos individuales dentro de una partida
DROP TABLE IF EXISTS games CASCADE;
CREATE TABLE games (
    id SERIAL PRIMARY KEY,
    match_id INTEGER REFERENCES matches(id) ON DELETE CASCADE,
    game_number INTEGER NOT NULL,
    team1_score INTEGER,
    team2_score INTEGER,
    winner_team INTEGER CHECK (winner_team IN (1, 2)),
    duration_minutes INTEGER,
    moves JSONB, -- Registro de movimientos si se requiere
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Histórico de ratings ELO
DROP TABLE IF EXISTS elo_history CASCADE;
CREATE TABLE elo_history (
    id SERIAL PRIMARY KEY,
    player_id INTEGER REFERENCES players(id) ON DELETE CASCADE,
    match_id INTEGER REFERENCES matches(id),
    rating_type VARCHAR(20) NOT NULL CHECK (rating_type IN ('official', 'open')),
    old_rating INTEGER NOT NULL,
    new_rating INTEGER NOT NULL,
    rating_change INTEGER NOT NULL,
    opponent1_id INTEGER REFERENCES players(id),
    opponent2_id INTEGER REFERENCES players(id),
    result VARCHAR(10) CHECK (result IN ('win', 'loss', 'draw')),
    k_factor INTEGER, -- Factor K usado en el cálculo ELO
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Rankings
DROP TABLE IF EXISTS rankings CASCADE;
CREATE TABLE rankings (
    id SERIAL PRIMARY KEY,
    ranking_type VARCHAR(20) NOT NULL CHECK (ranking_type IN ('official', 'open')),
    player_id INTEGER REFERENCES players(id) ON DELETE CASCADE,
    organization_id INTEGER REFERENCES organizations(id), -- Organización que avala (para oficial)
    current_rating INTEGER NOT NULL,
    previous_rating INTEGER,
    position INTEGER,
    previous_position INTEGER,
    games_played INTEGER DEFAULT 0,
    wins INTEGER DEFAULT 0,
    losses INTEGER DEFAULT 0,
    draws INTEGER DEFAULT 0,
    win_percentage DECIMAL(5,2),
    active_since TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_game_date TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(ranking_type, player_id, organization_id)
);

-- Pagos y facturación
DROP TABLE IF EXISTS payments CASCADE;
CREATE TABLE payments (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    license_id INTEGER REFERENCES user_licenses(id),
    tournament_id INTEGER REFERENCES tournaments(id), -- Para pagos de inscripción
    payment_type VARCHAR(20) NOT NULL CHECK (payment_type IN ('license', 'tournament')),
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'USD',
    payment_method VARCHAR(50), -- 'stripe', 'paypal', etc.
    payment_reference VARCHAR(200),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed', 'refunded')),
    payment_date TIMESTAMP,
    invoice_number VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Notificaciones
DROP TABLE IF EXISTS notifications CASCADE;
CREATE TABLE notifications (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50), -- 'tournament', 'payment', 'system', etc.
    related_id INTEGER, -- ID relacionado (torneo, pago, etc.)
    is_read BOOLEAN DEFAULT false,
    is_sent BOOLEAN DEFAULT false,
    send_email BOOLEAN DEFAULT false,
    send_push BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP
);

-- Configuración del sistema
DROP TABLE IF EXISTS system_config CASCADE;
CREATE TABLE system_config (
    id SERIAL PRIMARY KEY,
    config_key VARCHAR(100) UNIQUE NOT NULL,
    config_value TEXT,
    description TEXT,
    data_type VARCHAR(20) DEFAULT 'string', -- 'string', 'number', 'boolean', 'json'
    is_editable BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- ÍNDICES PARA OPTIMIZACIÓN
-- =====================================================

-- Índices para users
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_active ON users(is_active);

-- Índices para licencias
CREATE INDEX idx_user_licenses_user_active ON user_licenses(user_id, is_active);
CREATE INDEX idx_user_licenses_dates ON user_licenses(start_date, end_date);

-- Índices para sesiones
CREATE INDEX idx_active_sessions_user ON active_sessions(user_id, is_active);
CREATE INDEX idx_active_sessions_token ON active_sessions(session_token);

-- Índices para organizaciones
CREATE INDEX idx_organizations_type ON organizations(organization_type_id);
CREATE INDEX idx_organizations_parent ON organizations(parent_organization_id);
CREATE INDEX idx_organizations_verified ON organizations(is_verified, is_active);

-- Índices para jugadores
CREATE INDEX idx_players_user ON players(user_id);
CREATE INDEX idx_players_official_rating ON players(elo_rating_official DESC);
CREATE INDEX idx_players_open_rating ON players(elo_rating_open DESC);

-- Índices para torneos
CREATE INDEX idx_tournaments_organizer ON tournaments(organizing_entity_id);
CREATE INDEX idx_tournaments_dates ON tournaments(start_date, end_date);
CREATE INDEX idx_tournaments_status ON tournaments(status);
CREATE INDEX idx_tournaments_type ON tournaments(tournament_type);

-- Índices para partidas
CREATE INDEX idx_matches_tournament ON matches(tournament_id);
CREATE INDEX idx_matches_players ON matches(team1_player1_id, team1_player2_id, team2_player1_id, team2_player2_id);
CREATE INDEX idx_matches_dates ON matches(scheduled_time, start_time);

-- Índices para ranking
CREATE INDEX idx_rankings_type_rating ON rankings(ranking_type, current_rating DESC);
CREATE INDEX idx_rankings_player ON rankings(player_id, ranking_type);

-- =====================================================
-- TRIGGERS PARA ACTUALIZACIÓN AUTOMÁTICA
-- =====================================================

-- Función para actualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Aplicar trigger a las tablas que lo necesiten
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_organizations_updated_at BEFORE UPDATE ON organizations 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_players_updated_at BEFORE UPDATE ON players 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_referees_updated_at BEFORE UPDATE ON referees 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tournaments_updated_at BEFORE UPDATE ON tournaments 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_matches_updated_at BEFORE UPDATE ON matches 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_rankings_updated_at BEFORE UPDATE ON rankings 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- DATOS INICIALES
-- =====================================================

-- Tipos de licencias
INSERT INTO license_types (name, description, monthly_price, annual_price, max_simultaneous_sessions, features) VALUES
('basica', 'Licencia básica con funcionalidades esenciales', 9.99, 99.99, 1, '{"tournaments": true, "basic_stats": true, "elo_tracking": true}'),
('premium', 'Licencia premium con todas las funcionalidades', 19.99, 199.99, 3, '{"tournaments": true, "advanced_stats": true, "elo_tracking": true, "custom_tournaments": true, "detailed_analytics": true, "priority_support": true}');

-- Tipos de organizaciones
INSERT INTO organization_types (name, description, hierarchy_level) VALUES
('FID', 'Federación Internacional de Dominó', 1),
('federation', 'Federación Nacional', 2),
('association', 'Asociación Regional/Estatal', 3),
('club', 'Club Local', 4);

-- Roles de usuarios
INSERT INTO user_roles (name, description, permissions) VALUES
('admin', 'Administrador con todos los permisos', '{"manage_users": true, "manage_tournaments": true, "manage_system": true, "verify_organizations": true}'),
('moderator', 'Moderador con permisos limitados', '{"manage_tournaments": true, "verify_players": true}'),
('player', 'Jugador registrado', '{"participate_tournaments": true, "view_rankings": true}'),
('referee', 'Árbitro certificado', '{"officiate_matches": true, "validate_results": true}'),
('fan', 'Aficionado sin permisos especiales', '{"view_tournaments": true, "view_rankings": true}');

-- Modalidades de juego básicas
INSERT INTO game_modes (name, description, min_players, max_players, is_team_mode, license_required) VALUES
('sistema_suizo', 'Sistema Suizo para torneos', 8, 1000, true, 'basica'),
('eliminacion_directa', 'Eliminación directa por parejas', 4, 64, true, 'basica'),
('round_robin', 'Todos contra todos (Round Robin)', 6, 32, true, 'premium'),
('escalera', 'Sistema de escalera clasificatoria', 4, 100, true, 'premium');

-- Configuración inicial del sistema
INSERT INTO system_config (config_key, config_value, description, data_type) VALUES
('default_elo_rating', '1200', 'Rating ELO inicial para nuevos jugadores', 'number'),
('elo_k_factor', '32', 'Factor K para cálculo de rating ELO', 'number'),
('min_rating_change', '1', 'Cambio mínimo de rating por partida', 'number'),
('max_rating_change', '50', 'Cambio máximo de rating por partida', 'number'),
('tournament_registration_days', '30', 'Días máximos para inscripción anticipada', 'number'),
('system_currency', 'USD', 'Moneda por defecto del sistema', 'string'),
('maintenance_mode', 'false', 'Modo de mantenimiento activado', 'boolean');

-- =====================================================
-- COMENTARIOS FINALES
-- =====================================================

-- Este esquema incluye:
-- 1. Gestión completa de usuarios, licencias y sesiones
-- 2. Jerarquía de organizaciones (FID -> Federaciones -> Asociaciones -> Clubes)
-- 3. Sistema de verificación y aprobación jerárquica
-- 4. Gestión de jugadores, árbitros y roles
-- 5. Sistema completo de torneos con múltiples modalidades
-- 6. Ranking ELO dual (oficial/abierto) con histórico
-- 7. Sistema de pagos y facturación
-- 8. Notificaciones y configuración del sistema
-- 9. Índices optimizados para consultas frecuentes
-- 10. Triggers para mantenimiento automático de timestamps