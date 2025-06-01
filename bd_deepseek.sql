-- Extensión del esquema existente para incluir todas las tablas necesarias

-- Tablas de usuarios y autenticación (extendiendo las existentes)
ALTER TABLE "user" ADD COLUMN verification_status VARCHAR(20) NOT NULL DEFAULT 'unverified';
ALTER TABLE "user" ADD COLUMN verification_document_url VARCHAR(255);
ALTER TABLE "user" ADD COLUMN verification_social_url VARCHAR(255);
ALTER TABLE "user" ADD COLUMN last_login TIMESTAMP WITH TIME ZONE;
ALTER TABLE "user" ADD COLUMN license_type VARCHAR(10); -- 'basic' or 'premium'
ALTER TABLE "user" ADD COLUMN license_expires_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE "user" ADD COLUMN current_session_id VARCHAR(255);

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

-- Tabla de organizaciones (FID, federaciones, asociaciones, clubes)
CREATE TABLE organization (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_organization_id UUID REFERENCES organization(id),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    organization_type VARCHAR(20) NOT NULL, -- 'fid', 'federation', 'association', 'club'
    country_code VARCHAR(2),
    region VARCHAR(100), -- estado/provincia/departamento para asociaciones
    verification_status VARCHAR(20) NOT NULL DEFAULT 'pending', -- pending, approved, rejected
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
    is_primary BOOLEAN DEFAULT FALSE, -- si es el representante principal
    joined_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, organization_id)
);

-- Tabla de torneos
CREATE TABLE tournament (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID REFERENCES organization(id),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    tournament_type VARCHAR(50) NOT NULL, -- 'swiss', 'round_robin', 'elimination', etc.
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    location VARCHAR(255),
    is_official BOOLEAN NOT NULL DEFAULT FALSE,
    status VARCHAR(20) NOT NULL DEFAULT 'planned', -- planned, ongoing, completed, canceled
    ruleset JSONB, -- Configuración específica del torneo
    created_by UUID REFERENCES "user"(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Tabla de participantes en torneos
CREATE TABLE tournament_participant (
    tournament_id UUID REFERENCES tournament(id) ON DELETE CASCADE,
    user_id UUID REFERENCES "user"(id) ON DELETE CASCADE,
    partner_user_id UUID REFERENCES "user"(id), -- para torneos en parejas
    team_name VARCHAR(255),
    initial_rating INT, -- ELO al inicio del torneo
    final_position INT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    PRIMARY KEY (tournament_id, user_id)
);

-- Tabla de rondas/matches
CREATE TABLE tournament_match (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id UUID REFERENCES tournament(id) ON DELETE CASCADE,
    round_number INT NOT NULL,
    table_number INT,
    start_time TIMESTAMP WITH TIME ZONE,
    end_time TIMESTAMP WITH TIME ZONE,
    status VARCHAR(20) NOT NULL DEFAULT 'scheduled', -- scheduled, in_progress, completed, canceled
    referee_id UUID REFERENCES "user"(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Tabla de resultados de matches
CREATE TABLE match_result (
    match_id UUID REFERENCES tournament_match(id) ON DELETE CASCADE,
    participant1_user_id UUID REFERENCES "user"(id),
    participant2_user_id UUID REFERENCES "user"(id),
    participant1_score INT NOT NULL,
    participant2_score INT NOT NULL,
    winner_user_id UUID REFERENCES "user"(id), -- puede ser null para empates
    is_draw BOOLEAN NOT NULL DEFAULT FALSE,
    reported_by UUID REFERENCES "user"(id),
    verified_by UUID REFERENCES "user"(id),
    verification_status VARCHAR(20) NOT NULL DEFAULT 'pending', -- pending, approved, rejected
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    PRIMARY KEY (match_id)
);

-- Tabla de historial de ratings ELO
CREATE TABLE elo_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES "user"(id) ON DELETE CASCADE,
    rating_type VARCHAR(10) NOT NULL, -- 'official' or 'open'
    old_rating INT NOT NULL,
    new_rating INT NOT NULL,
    change INT NOT NULL,
    match_id UUID REFERENCES tournament_match(id),
    tournament_id UUID REFERENCES tournament(id),
    change_reason VARCHAR(255), -- 'tournament', 'manual_adjustment', etc.
    changed_by UUID REFERENCES "user"(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
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

-- Tabla de sesiones activas (para control de doble sesión)
CREATE TABLE active_session (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES "user"(id) ON DELETE CASCADE,
    session_token VARCHAR(255) NOT NULL,
    ip_address VARCHAR(45) NOT NULL,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL
);

-- Tabla de características de licencia
CREATE TABLE license_feature (
    license_type VARCHAR(10) PRIMARY KEY, -- 'basic' or 'premium'
    max_organizations INT,
    max_tournaments INT,
    max_participants INT,
    available_game_types TEXT[], -- tipos de torneos disponibles
    has_detailed_stats BOOLEAN NOT NULL DEFAULT FALSE,
    allow_multiple_sessions BOOLEAN NOT NULL DEFAULT FALSE,
    can_create_official_tournaments BOOLEAN NOT NULL DEFAULT FALSE,
    can_verify_players BOOLEAN NOT NULL DEFAULT FALSE
);

-- Insertar características de licencias básicas y premium
INSERT INTO license_feature (license_type, max_organizations, max_tournaments, max_participants, available_game_types, has_detailed_stats, allow_multiple_sessions, can_create_official_tournaments, can_verify_players)
VALUES 
('basic', 1, 5, 50, '{"swiss"}', FALSE, FALSE, FALSE, FALSE),
('premium', 10, 100, 1000, '{"swiss", "round_robin", "elimination", "double_elimination"}', TRUE, TRUE, TRUE, TRUE);

-- Tabla de notificaciones
CREATE TABLE notification (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES "user"(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    notification_type VARCHAR(50) NOT NULL,
    related_entity_type VARCHAR(50), -- 'tournament', 'match', 'organization', etc.
    related_entity_id UUID, -- ID del torneo, partido, etc.
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Tabla de solicitudes de verificación
CREATE TABLE verification_request (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES "user"(id) ON DELETE CASCADE,
    organization_id UUID REFERENCES organization(id) ON DELETE CASCADE,
    request_type VARCHAR(50) NOT NULL, -- 'user_verification', 'organization_approval'
    status VARCHAR(20) NOT NULL DEFAULT 'pending', -- pending, approved, rejected
    document_url VARCHAR(255),
    social_verification_url VARCHAR(255),
    reviewed_by UUID REFERENCES "user"(id),
    review_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);