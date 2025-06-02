-- =====================================================
-- SISTEMA DE DOMINÓ PROFESIONAL - ESQUEMA UNIFICADO
-- =====================================================

-- Tabla de usuarios base
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
    max_concurrent_tournaments INTEGER DEFAULT 1,
    can_publish_events BOOLEAN DEFAULT false,
    can_request_endorsements BOOLEAN DEFAULT false, -- Unificado (plural)
    features JSONB,
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

-- Sesiones activas
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
    can_endorse_level INTEGER, -- Qué nivel puede avalar (NULL = ninguno)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Organizaciones
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
    verification_document VARCHAR(500),
    social_media_links JSONB,
    is_verified BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    verification_date TIMESTAMP,
    verified_by INTEGER REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Roles de usuarios en organizaciones
DROP TABLE IF EXISTS user_roles CASCADE;
CREATE TABLE user_roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL, -- 'admin', 'moderator', 'player', 'referee', 'fan', etc.
    description TEXT,
    permissions JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Relación usuarios con organizaciones y roles
DROP TABLE IF EXISTS user_organization_roles CASCADE;
CREATE TABLE user_organization_roles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    organization_id INTEGER REFERENCES organizations(id) ON DELETE CASCADE,
    role_id INTEGER REFERENCES user_roles(id),
    is_verified BOOLEAN DEFAULT false,
    verification_document VARCHAR(500),
    verified_by INTEGER REFERENCES users(id),
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
    player_number VARCHAR(50),
    -- ELO por tipo de ranking (fusionado de Esquema 2)
    elo_rating_universal INTEGER DEFAULT 1200,
    elo_rating_national INTEGER DEFAULT 1200,
    elo_rating_regional INTEGER DEFAULT 1200,
    elo_rating_local INTEGER DEFAULT 1200,
    -- Estadísticas por tipo (fusionado de Esquema 2)
    games_played_universal INTEGER DEFAULT 0,
    games_played_national INTEGER DEFAULT 0,
    games_played_regional INTEGER DEFAULT 0,
    games_played_local INTEGER DEFAULT 0,
    -- Mejores ratings alcanzados (fusionado de Esquema 2)
    best_rating_universal INTEGER DEFAULT 1200,
    best_rating_national INTEGER DEFAULT 1200,
    best_rating_regional INTEGER DEFAULT 1200,
    best_rating_local INTEGER DEFAULT 1200,
    -- Estadísticas generales
    total_tournaments_played INTEGER DEFAULT 0, -- (fusionado de Esquema 2)
    total_wins INTEGER DEFAULT 0, -- (fusionado de Esquema 2)
    total_losses INTEGER DEFAULT 0, -- (fusionado de Esquema 2)
    current_streak INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    preferred_partner INTEGER REFERENCES players(id), -- (de Esquema 2)
    is_seeking_partner BOOLEAN DEFAULT false,
    playing_style TEXT,
    achievements JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Árbitros
DROP TABLE IF EXISTS referees CASCADE;
CREATE TABLE referees (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    referee_number VARCHAR(50),
    certification_level VARCHAR(50),
    certification_date DATE,
    certification_expires DATE,
    certifying_organization_id INTEGER REFERENCES organizations(id),
    languages JSONB,
    specializations JSONB,
    tournaments_officiated INTEGER DEFAULT 0,
    rating DECIMAL(3,2) DEFAULT 5.00,
    is_active BOOLEAN DEFAULT true,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Modalidades de juego específicas del dominó
DROP TABLE IF EXISTS game_modes CASCADE;
CREATE TABLE game_modes (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL, 
    display_name VARCHAR(100) NOT NULL, -- (de Esquema 1)
    description TEXT,
    min_players INTEGER NOT NULL,
    max_players INTEGER,
    is_team_mode BOOLEAN DEFAULT true,
    pairing_algorithm VARCHAR(50), -- (de Esquema 1)
    rounds_calculation VARCHAR(50), -- (de Esquema 1)
    scoring_system JSONB, -- Detalle del sistema de puntuación base para esta modalidad
    rules JSONB,
    license_required VARCHAR(20) DEFAULT 'basica',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sistemas de puntuación por ronda
DROP TABLE IF EXISTS scoring_systems CASCADE;
CREATE TABLE scoring_systems (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL, 
    display_name VARCHAR(100) NOT NULL, -- (de Esquema 1)
    description TEXT,
    target_points INTEGER, 
    cycles_per_round INTEGER, -- (nombre de Esquema 1)
    hands_per_cycle INTEGER DEFAULT 4, 
    is_active BOOLEAN DEFAULT true, -- (de Esquema 2)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices estadísticos predefinidos (de Esquema 1)
DROP TABLE IF EXISTS statistical_indices CASCADE;
CREATE TABLE statistical_indices (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    display_name VARCHAR(100) NOT NULL,
    description TEXT,
    formula TEXT NOT NULL, 
    calculation_order INTEGER, 
    data_type VARCHAR(20) DEFAULT 'decimal', 
    decimal_places INTEGER DEFAULT 2,
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
    organized_by INTEGER REFERENCES users(id),
    game_mode_id INTEGER REFERENCES game_modes(id),
    scoring_system_id INTEGER REFERENCES scoring_systems(id), 
    tournament_type VARCHAR(20) NOT NULL CHECK (tournament_type IN ('official', 'open')),
    ranking_level VARCHAR(20) NOT NULL CHECK (ranking_level IN ('universal', 'national', 'regional', 'local')), -- (de Esquema 2)
    
    -- Sistema de avales (fusionado, con base en Esquema 2)
    endorsement_requested BOOLEAN DEFAULT false,
    endorsement_level VARCHAR(20), -- Nivel de aval solicitado (ej. 'national', 'regional')
    endorsing_organization_id INTEGER REFERENCES organizations(id), -- Organización que avala
    endorsement_status VARCHAR(20) DEFAULT 'none' CHECK (endorsement_status IN ('none', 'pending', 'requested', 'approved', 'rejected', 'under_review')),
    endorsement_date TIMESTAMP,
    endorsed_by INTEGER REFERENCES users(id),
    endorsement_notes TEXT, -- (nombre unificado)
    
    -- Configuración de rondas
    total_rounds INTEGER NOT NULL DEFAULT 5, 
    current_round INTEGER DEFAULT 0, -- (de Esquema 2)
    
    registration_start TIMESTAMP,
    registration_end TIMESTAMP,
    start_date TIMESTAMP,
    end_date TIMESTAMP,
    venue_name VARCHAR(200),
    venue_address TEXT,
    city VARCHAR(100),
    country VARCHAR(100),
    max_participants INTEGER,
    min_participants INTEGER DEFAULT 4, -- (de Esquema 2)
    entry_fee DECIMAL(10,2) DEFAULT 0,
    prize_pool DECIMAL(10,2) DEFAULT 0,
    prize_distribution JSONB,
    registration_requirements JSONB,
    rules JSONB,
    contact_info JSONB,
    poster_url VARCHAR(500),
    live_streaming_url VARCHAR(500),
    is_rated BOOLEAN DEFAULT true,
    is_public_event BOOLEAN DEFAULT false,
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'registration', 'ongoing', 'finished', 'cancelled')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Inscripciones a torneos
DROP TABLE IF EXISTS tournament_registrations CASCADE;
CREATE TABLE tournament_registrations (
    id SERIAL PRIMARY KEY,
    tournament_id INTEGER REFERENCES tournaments(id) ON DELETE CASCADE,
    player_id INTEGER REFERENCES players(id), 
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'cancelled')),
    payment_status VARCHAR(20) DEFAULT 'unpaid' CHECK (payment_status IN ('unpaid', 'paid', 'refunded')),
    payment_date TIMESTAMP,
    payment_reference VARCHAR(100),
    notes TEXT,
    seeding_number INTEGER,
    UNIQUE(tournament_id, player_id)
);

-- Rondas de torneos
DROP TABLE IF EXISTS tournament_rounds CASCADE;
CREATE TABLE tournament_rounds (
    id SERIAL PRIMARY KEY,
    tournament_id INTEGER REFERENCES tournaments(id) ON DELETE CASCADE,
    round_number INTEGER NOT NULL,
    round_name VARCHAR(100),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'ongoing', 'finished')),
    scoring_system_id INTEGER REFERENCES scoring_systems(id), 
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    pairing_generated BOOLEAN DEFAULT false, -- (de Esquema 1)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Parejas por ronda (de Esquema 1, para sistema rotativo o donde las parejas se forman por ronda)
DROP TABLE IF EXISTS round_pairings CASCADE;
CREATE TABLE round_pairings (
    id SERIAL PRIMARY KEY,
    tournament_id INTEGER REFERENCES tournaments(id) ON DELETE CASCADE,
    round_id INTEGER REFERENCES tournament_rounds(id) ON DELETE CASCADE,
    player1_id INTEGER REFERENCES players(id),
    player2_id INTEGER REFERENCES players(id),
    table_number INTEGER,
    pairing_algorithm_data JSONB, 
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(round_id, player1_id),
    UNIQUE(round_id, player2_id),
    CHECK (player1_id <> player2_id)
);

-- Partidas (enfrentamientos entre dos parejas formadas en round_pairings)
DROP TABLE IF EXISTS matches CASCADE;
CREATE TABLE matches (
    id SERIAL PRIMARY KEY,
    tournament_id INTEGER REFERENCES tournaments(id),
    round_id INTEGER REFERENCES tournament_rounds(id),
    pairing1_id INTEGER REFERENCES round_pairings(id), -- Pareja 1 (de Esquema 1)
    pairing2_id INTEGER REFERENCES round_pairings(id), -- Pareja 2 (de Esquema 1)
    match_number INTEGER,
    table_number INTEGER,
    referee_id INTEGER REFERENCES referees(id),
    status VARCHAR(20) DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'ongoing', 'finished', 'cancelled')),
    scheduled_time TIMESTAMP,
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    
    -- Resultados (de Esquema 1)
    pareja1_points_favor INTEGER DEFAULT 0, 
    pareja1_points_contra INTEGER DEFAULT 0, 
    pareja2_points_favor INTEGER DEFAULT 0, 
    pareja2_points_contra INTEGER DEFAULT 0, 
    winner_pairing INTEGER CHECK (winner_pairing IN (1, 2)), -- Qué pareja de round_pairings ganó
    
    games_detail JSONB, 
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
    pareja1_score INTEGER, -- Score de la pareja referenciada por matches.pairing1_id
    pareja2_score INTEGER, -- Score de la pareja referenciada por matches.pairing2_id
    winner_pairing INTEGER CHECK (winner_pairing IN (1, 2)), -- Qué pareja (1 o 2 de la partida) ganó este juego
    starting_player_id INTEGER REFERENCES players(id), -- (nombre unificado)
    duration_minutes INTEGER,
    moves JSONB, 
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Estadísticas de jugadores por torneo (fusionado, con base en estructura de Esquema 2 tournament_standings)
DROP TABLE IF EXISTS tournament_player_stats CASCADE;
CREATE TABLE tournament_player_stats (
    id SERIAL PRIMARY KEY,
    tournament_id INTEGER REFERENCES tournaments(id) ON DELETE CASCADE,
    player_id INTEGER REFERENCES players(id) ON DELETE CASCADE,
    
    -- Estadísticas básicas
    matches_played INTEGER DEFAULT 0,
    matches_won INTEGER DEFAULT 0,
    matches_lost INTEGER DEFAULT 0,
    points_favor INTEGER DEFAULT 0,
    points_against INTEGER DEFAULT 0,
    
    -- Índices estadísticos (nombres descriptivos de Esquema 2)
    point_differential INTEGER DEFAULT 0, 
    win_percentage DECIMAL(5,2) DEFAULT 0.00, 
    average_points_favor DECIMAL(8,2) DEFAULT 0.00, 
    average_points_against DECIMAL(8,2) DEFAULT 0.00, 
    efficiency_ratio DECIMAL(6,4) DEFAULT 0.0000, 
    consistency_index DECIMAL(6,4) DEFAULT 0.0000, 
    performance_rating DECIMAL(8,2) DEFAULT 0.00, 
    dominance_factor DECIMAL(6,4) DEFAULT 0.0000, 
    clutch_performance DECIMAL(6,4) DEFAULT 0.0000, 
    partnership_adaptability DECIMAL(6,4) DEFAULT 0.0000, 
    closing_ability DECIMAL(6,4) DEFAULT 0.0000, 
    comeback_ratio DECIMAL(6,4) DEFAULT 0.0000, 
    tactical_score DECIMAL(8,2) DEFAULT 0.00, 
    
    current_position INTEGER,
    previous_position INTEGER, -- (de Esquema 2)
    final_position INTEGER, -- (de Esquema 1)
    
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(tournament_id, player_id)
);

-- Histórico de ratings ELO
DROP TABLE IF EXISTS elo_history CASCADE;
CREATE TABLE elo_history (
    id SERIAL PRIMARY KEY,
    player_id INTEGER REFERENCES players(id) ON DELETE CASCADE,
    tournament_id INTEGER REFERENCES tournaments(id), 
    match_id INTEGER REFERENCES matches(id),
    rating_type VARCHAR(20) NOT NULL CHECK (rating_type IN ('universal', 'national', 'regional', 'local')), -- (de Esquema 2)
    old_rating INTEGER NOT NULL,
    new_rating INTEGER NOT NULL,
    rating_change INTEGER NOT NULL,
    partner_id INTEGER REFERENCES players(id), 
    opponent1_id INTEGER REFERENCES players(id),
    opponent2_id INTEGER REFERENCES players(id),
    result VARCHAR(10) CHECK (result IN ('win', 'loss', 'draw')), -- Permitir 'draw'
    k_factor INTEGER,
    endorsement_multiplier DECIMAL(3,2) DEFAULT 1.00, -- (de Esquema 1)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Rankings (fusionado de Esquema 2 global_rankings, nombre 'rankings' de Esquema 1)
DROP TABLE IF EXISTS rankings CASCADE;
CREATE TABLE rankings (
    id SERIAL PRIMARY KEY,
    ranking_type VARCHAR(20) NOT NULL CHECK (ranking_type IN ('universal', 'national', 'regional', 'local')),
    player_id INTEGER REFERENCES players(id) ON DELETE CASCADE,
    organization_id INTEGER REFERENCES organizations(id), 
    country VARCHAR(100), 
    region VARCHAR(100), 
    current_rating INTEGER NOT NULL,
    previous_rating INTEGER,
    position INTEGER,
    previous_position INTEGER,
    tournaments_played INTEGER DEFAULT 0,
    total_matches INTEGER DEFAULT 0,
    total_wins INTEGER DEFAULT 0,
    total_losses INTEGER DEFAULT 0,
    win_percentage DECIMAL(5,2),
    points_favor INTEGER DEFAULT 0,
    points_against INTEGER DEFAULT 0,
    point_differential INTEGER DEFAULT 0,
    active_since TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_tournament_date TIMESTAMP, -- (nombre de Esquema 2, vs last_game_date)
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(ranking_type, player_id, organization_id, country, region) -- Ajustado para unicidad
);

-- Solicitudes de aval
DROP TABLE IF EXISTS endorsement_requests CASCADE;
CREATE TABLE endorsement_requests (
    id SERIAL PRIMARY KEY,
    tournament_id INTEGER REFERENCES tournaments(id) ON DELETE CASCADE,
    requesting_organization_id INTEGER REFERENCES organizations(id), 
    requested_by INTEGER REFERENCES users(id),
    target_organization_id INTEGER REFERENCES organizations(id), 
    requested_level VARCHAR(20) NOT NULL, -- (de Esquema 2)
    justification TEXT NOT NULL, -- (de Esquema 2)
    supporting_documents JSONB, -- (de Esquema 2)
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'under_review', 'approved', 'rejected')),
    reviewed_by INTEGER REFERENCES users(id),
    review_date TIMESTAMP,
    review_comments TEXT, -- (de Esquema 2, unificado)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Eventos públicos (calendario)
DROP TABLE IF EXISTS public_events CASCADE;
CREATE TABLE public_events (
    id SERIAL PRIMARY KEY,
    tournament_id INTEGER REFERENCES tournaments(id), 
    title VARCHAR(200) NOT NULL,
    description TEXT,
    event_date TIMESTAMP NOT NULL,
    event_time TIME, -- (de Esquema 2)
    end_date TIMESTAMP,
    venue_name VARCHAR(200), -- (nombre unificado)
    address TEXT, -- (nombre unificado)
    city VARCHAR(100),
    country VARCHAR(100),
    entry_fee DECIMAL(10,2) DEFAULT 0,
    prize_amount DECIMAL(10,2) DEFAULT 0, -- (de Esquema 2)
    prize_description TEXT, -- (de Esquema 1)
    max_participants INTEGER, -- (de Esquema 2)
    contact_info JSONB,
    registration_url VARCHAR(500), -- (de Esquema 2)
    poster_url VARCHAR(500),
    organized_by_user_id INTEGER REFERENCES users(id), -- (nombre unificado)
    organized_by_organization_id INTEGER REFERENCES organizations(id), -- (nombre unificado)
    category VARCHAR(50), -- (de Esquema 2, ej: 'tournament', 'exhibition')
    is_active BOOLEAN DEFAULT true,
    is_featured BOOLEAN DEFAULT false, -- (de Esquema 2)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Pagos y facturación
DROP TABLE IF EXISTS payments CASCADE;
CREATE TABLE payments (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    license_id INTEGER REFERENCES user_licenses(id),
    tournament_id INTEGER REFERENCES tournaments(id),
    payment_type VARCHAR(20) NOT NULL CHECK (payment_type IN ('license', 'tournament')),
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'USD',
    payment_method VARCHAR(50),
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
    type VARCHAR(50),
    related_id INTEGER,
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
    data_type VARCHAR(20) DEFAULT 'string',
    is_editable BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- ÍNDICES PARA OPTIMIZACIÓN (Fusionados y Actualizados)
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

-- Índices para jugadores (actualizado a nuevos campos ELO)
CREATE INDEX idx_players_user ON players(user_id);
CREATE INDEX idx_players_universal_rating ON players(elo_rating_universal DESC);
CREATE INDEX idx_players_national_rating ON players(elo_rating_national DESC);
CREATE INDEX idx_players_regional_rating ON players(elo_rating_regional DESC);
CREATE INDEX idx_players_local_rating ON players(elo_rating_local DESC);
CREATE INDEX idx_players_total_tournaments ON players(total_tournaments_played DESC);

-- Índices para torneos
CREATE INDEX idx_tournaments_organizer_entity ON tournaments(organizing_entity_id);
CREATE INDEX idx_tournaments_dates ON tournaments(start_date, end_date);
CREATE INDEX idx_tournaments_status ON tournaments(status);
CREATE INDEX idx_tournaments_ranking_level ON tournaments(ranking_level);
CREATE INDEX idx_tournaments_endorsement ON tournaments(endorsement_status, endorsing_organization_id);

-- Índices para rondas y pareos
CREATE INDEX idx_tournament_rounds_tournament ON tournament_rounds(tournament_id);
CREATE INDEX idx_round_pairings_round ON round_pairings(round_id);
CREATE INDEX idx_round_pairings_players ON round_pairings(player1_id, player2_id);

-- Índices para partidas
CREATE INDEX idx_matches_tournament ON matches(tournament_id);
CREATE INDEX idx_matches_round ON matches(round_id);
CREATE INDEX idx_matches_pairings ON matches(pairing1_id, pairing2_id);
CREATE INDEX idx_matches_dates ON matches(scheduled_time, start_time);


-- Índices para estadísticas de torneo (tournament_player_stats)
CREATE INDEX idx_tournament_player_stats_tournament ON tournament_player_stats(tournament_id);
CREATE INDEX idx_tournament_player_stats_player ON tournament_player_stats(player_id);
CREATE INDEX idx_tournament_player_stats_position ON tournament_player_stats(tournament_id, current_position);

-- Índices para rankings (globales)
CREATE INDEX idx_rankings_type_rating ON rankings(ranking_type, current_rating DESC);
CREATE INDEX idx_rankings_player ON rankings(player_id, ranking_type);
CREATE INDEX idx_rankings_country ON rankings(ranking_type, country, current_rating DESC);
CREATE INDEX idx_rankings_region ON rankings(ranking_type, region, current_rating DESC);
CREATE INDEX idx_rankings_organization ON rankings(organization_id, ranking_type); -- (de Esquema 1)

-- Índices para eventos públicos
CREATE INDEX idx_public_events_date ON public_events(event_date);
CREATE INDEX idx_public_events_organizer_user ON public_events(organized_by_user_id);
CREATE INDEX idx_public_events_organizer_org ON public_events(organized_by_organization_id);
CREATE INDEX idx_public_events_active ON public_events(is_active, is_featured);
CREATE INDEX idx_public_events_location ON public_events(country, city); -- (de Esquema 1)

-- =====================================================
-- TRIGGERS Y FUNCIONES (Fusionados)
-- =====================================================

-- Función para actualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Aplicar triggers de updated_at (lista consolidada)
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_organizations_updated_at BEFORE UPDATE ON organizations 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_players_updated_at BEFORE UPDATE ON players 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_referees_updated_at BEFORE UPDATE ON referees  -- Añadido de Esquema 2
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_tournaments_updated_at BEFORE UPDATE ON tournaments 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_matches_updated_at BEFORE UPDATE ON matches -- Añadido de Esquema 2
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_rankings_updated_at BEFORE UPDATE ON rankings -- Aplicado a la tabla fusionada 'rankings'
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_public_events_updated_at BEFORE UPDATE ON public_events -- Añadido de Esquema 2
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_system_config_updated_at BEFORE UPDATE ON system_config -- Asumido que debe tenerlo
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


-- Función para actualizar estadísticas del torneo
CREATE OR REPLACE FUNCTION update_player_stats_on_match_finish()
RETURNS TRIGGER AS $$
BEGIN
    -- Actualizar estadísticas cuando se completa una partida
    IF NEW.status = 'finished' AND OLD.status != 'finished' THEN
        -- Esta función debería recalcular y actualizar las estadísticas
        -- para los jugadores involucrados en la partida (NEW.pairing1_id, NEW.pairing2_id)
        -- en la tabla tournament_player_stats para el NEW.tournament_id.
        -- La lógica exacta de cálculo de los 13 índices va aquí o en otra función llamada.
        -- Ejemplo conceptual (no es la lógica completa):
        
        -- Obtener jugadores de pairing1
        -- PERFORM update_individual_player_stats(player_from_pairing1, NEW.tournament_id, ...);
        -- Obtener jugadores de pairing2
        -- PERFORM update_individual_player_stats(player_from_pairing2, NEW.tournament_id, ...);

        -- Placeholder: simplemente actualiza last_updated para los jugadores de la partida
        -- Se necesitaría una función más compleja para obtener los player_id de round_pairings
        -- y luego actualizar tournament_player_stats.
        -- Por simplicidad aquí, solo se marca que algo debe ocurrir.
        RAISE NOTICE 'Match % finished in tournament %, stats should be updated.', NEW.id, NEW.tournament_id;
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER trg_update_player_stats_on_match_finish AFTER UPDATE ON matches
    FOR EACH ROW EXECUTE FUNCTION update_player_stats_on_match_finish();

-- =====================================================
-- DATOS INICIALES (Fusionados y Ajustados)
-- =====================================================

-- Tipos de licencias
-- =====================================================

INSERT INTO license_types (name, description, monthly_price, annual_price, max_simultaneous_sessions, max_concurrent_tournaments, can_publish_events, can_request_endorsements, features) VALUES
('basica', 'Licencia básica con funcionalidades esenciales', 9.99, 99.99, 1, 1, false, false, '{"tournaments": true, "basic_stats": true, "elo_tracking": true}'),
('premium', 'Licencia premium con todas las funcionalidades', 19.99, 199.99, 3, 10, true, true, '{"tournaments": true, "advanced_stats": true, "elo_tracking": true, "custom_tournaments": true, "detailed_analytics": true, "priority_support": true, "public_events": true, "endorsement_requests": true}');

-- Tipos de organizaciones (datos de Esquema 2, FID puede avalar Federaciones)
INSERT INTO organization_types (name, description, hierarchy_level, can_endorse_level) VALUES
('FID', 'Federación Internacional de Dominó', 1, 2), 
('federation', 'Federación Nacional', 2, 3), 
('association', 'Asociación Regional/Estatal', 3, 4), 
('club', 'Club Local', 4, NULL);

-- Roles de usuarios (datos de Esquema 2)
INSERT INTO user_roles (name, description, permissions) VALUES
('admin', 'Administrador con todos los permisos', '{"manage_users": true, "manage_tournaments": true, "manage_system": true, "verify_organizations": true, "approve_endorsements": true}'),
('moderator', 'Moderador con permisos limitados', '{"manage_tournaments": true, "verify_players": true, "review_endorsements": true}'),
('player', 'Jugador registrado', '{"participate_tournaments": true, "view_rankings": true}'),
('referee', 'Árbitro certificado', '{"officiate_matches": true, "validate_results": true}'),
('fan', 'Aficionado sin permisos especiales', '{"view_tournaments": true, "view_rankings": true}');

-- Sistemas de puntuación (fusionado)
INSERT INTO scoring_systems (name, display_name, description, target_points, cycles_per_round, hands_per_cycle, is_active) VALUES
('200_puntos', 'A 200 Puntos', 'Juego hasta 200 puntos', 200, NULL, NULL, true),
('100_puntos', 'A 100 Puntos', 'Juego hasta 100 puntos', 100, NULL, NULL, true),
('ciclos', 'Por Ciclos', 'Juego por ciclos completos (4 manos)', NULL, 1, 4, true);

-- Modalidades de juego (fusionado, tomando display_name, etc. de Esquema 1 donde exista)
INSERT INTO game_modes (name, display_name, description, min_players, max_players, is_team_mode, pairing_algorithm, rounds_calculation, license_required, scoring_system, rules, is_active) VALUES
('sistema_suizo', 'Sistema Suizo', 'Pareo por puntuación similar', 8, 1000, true, 'suizo_domino', 'logaritmic', 'basica', '{"default_scoring": "200_puntos"}', '{"tie_break_rules": "buchholz"}', true),
('llave', 'Llave/Eliminación Directa', 'Eliminación directa por parejas', 4, 64, true, 'bracket_single', 'power_of_two', 'basica', '{"default_scoring": "200_puntos"}', NULL, true),
('liguilla', 'Liguilla/Round Robin', 'Todos contra todos', 6, 32, true, 'round_robin', 'combination', 'premium', '{"default_scoring": "100_puntos"}', NULL, true),
('patio', 'Sistema de Patio', 'Rotación libre en mesas', 8, 100, true, 'free_rotation', 'manual', 'premium', '{"default_scoring": "ciclos"}', NULL, true);

-- Índices estadísticos predefinidos (Completado basado en el contexto)
-- Los nombres de `name` aquí coinciden con los campos de `tournament_player_stats` para facilitar la referencia.
INSERT INTO statistical_indices (name, display_name, description, formula, calculation_order, data_type, decimal_places, is_active) VALUES
('average_points_favor', 'Promedio Puntos a Favor', 'Promedio de puntos anotados por el jugador por partida en el torneo.', 'SUM(player_points_favor_per_match) / matches_played', 1, 'decimal', 2, true),
('average_points_against', 'Promedio Puntos en Contra', 'Promedio de puntos recibidos por el jugador por partida en el torneo.', 'SUM(player_points_against_per_match) / matches_played', 2, 'decimal', 2, true),
('point_differential', 'Diferencial de Puntos', 'Diferencia total entre puntos a favor y puntos en contra del jugador en el torneo.', 'SUM(player_points_favor_per_match) - SUM(player_points_against_per_match)', 3, 'integer', 0, true),
('win_percentage', 'Porcentaje de Victorias', 'Porcentaje de partidas ganadas por el jugador en el torneo.', '(matches_won / matches_played) * 100', 4, 'percentage', 2, true),
('efficiency_ratio', 'Ratio de Eficiencia', 'Ratio entre puntos a favor y puntos en contra (PF/PC). Un valor > 1 indica más puntos anotados que recibidos.', 'SUM(player_points_favor_per_match) / SUM(player_points_against_per_match)', 5, 'decimal', 4, true),
('consistency_index', 'Índice de Consistencia', 'Medida de la variación en el rendimiento del jugador a lo largo del torneo (ej. desviación estándar de puntos por partida).', 'STDDEV(player_points_per_match_differential)', 6, 'decimal', 4, true),
('performance_rating', 'Rating de Rendimiento', 'Calificación general del rendimiento basada en múltiples factores (ELO del torneo, dificultad de oponentes).', 'COMPLEX_CALCULATION(elo, opponent_elo, results)', 10, 'decimal', 2, true),
('dominance_factor', 'Factor de Dominancia', 'Medida de cuán dominantemente un jugador gana sus partidas (ej. margen de victoria).', 'AVG(win_margin_when_won)', 7, 'decimal', 4, true),
('clutch_performance', 'Rendimiento Clutch', 'Rendimiento del jugador en momentos críticos o partidas decisivas.', 'WEIGHTED_AVG(performance_in_critical_games)', 8, 'decimal', 4, true),
('partnership_adaptability', 'Adaptabilidad de Pareja', 'Capacidad del jugador para rendir bien con diferentes compañeros (si aplica).', 'AVG_PERFORMANCE_ACROSS_PARTNERS()', 9, 'decimal', 4, true),
('closing_ability', 'Habilidad de Cierre', 'Capacidad del jugador para ganar partidas cuando tiene la ventaja.', 'WIN_RATE_WHEN_LEADING()', 11, 'decimal', 4, true),
('comeback_ratio', 'Ratio de Remontada', 'Capacidad del jugador para ganar partidas después de estar en desventaja.', 'WIN_RATE_WHEN_TRAILING_THEN_WIN()', 12, 'decimal', 4, true),
('tactical_score', 'Puntuación Táctica Compuesta', 'Una puntuación global que combina varios índices tácticos y de rendimiento.', 'WEIGHTED_SUM(index1, index2, ..., indexN)', 13, 'decimal', 2, true);
('liguilla', 'Liguilla/Round Robin', 'Todos contra todos', 6, 32, true, 'round_robin', 'combination', 'premium', '{"default_scoring": "100_puntos"}', NULL, true),
('patio', 'Sistema de Patio', 'Rotación libre en mesas', 8, 100, true, 'free_rotation', 'manual', 'premium', '{"default_scoring": "ciclos"}', NULL, true);

-- Índices estadísticos predefinidos (de Esquema 1 - INSERT INCOMPLETO, SE OMITE EL DATO HASTA TENERLO COMPLETO)
-- INSERT INTO statistical_indices (name, display_name, description, formula, calculation_order, data_type, decimal_places) VALUES
-- ('avg_points_favor', 'Promedio Puntos a Favor', 'Promedio de puntos anotados por partida', 'SUM(points_favor)...
