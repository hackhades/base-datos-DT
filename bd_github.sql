erDiagram
    user ||--o{ user_profile : "1:1"
    user ||--o{ organization_member : "1:N"
    user ||--o{ tournament_participant : "1:N"
    user ||--o{ elo_history : "1:N"
    user ||--o{ global_ranking : "1:1"
    user ||--o{ regional_ranking : "1:N"
    user ||--o{ license_subscription : "1:N"
    user ||--o{ active_session : "1:N"
    user ||--o{ notification : "1:N"
    user ||--o{ verification_request : "1:N"
    user ||--|{ game : "player1"
    user ||--|{ game : "player2"
    user ||--|{ game : "player3"
    user ||--|{ game : "player4"
    user ||--|{ game : "referee"
    user ||--|{ match_result : "reported_by"
    user ||--|{ match_result : "verified_by"
    user ||--|{ tournament : "created_by"
    user ||--|{ organization : "created_by"

    organization ||--o{ organization : "parent"
    organization ||--o{ organization_member : "1:N"
    organization ||--o{ tournament : "1:N"
    organization ||--o{ license_subscription : "1:N"
    organization ||--o{ verification_request : "1:N"
    organization ||--|{ tournament_approval_request : "requesting"
    organization ||--|{ tournament_approval_request : "approving"
    organization ||--|{ tournament : "approved_by"

    game_mode ||--o{ tournament : "1:N"

    tournament ||--o{ tournament_participant : "1:N"
    tournament ||--o{ tournament_round : "1:N"
    tournament ||--o{ tournament_ranking : "1:N"
    tournament ||--o{ elo_history : "1:N"
    tournament ||--|{ tournament_approval_request : "1:1"

    tournament_round ||--o{ game : "1:N"

    game ||--o{ match_result : "1:1"
    game ||--o{ elo_history : "1:N"

    license_feature ||--o{ license_subscription : "type"

    user {
        UUID id PK
        VARCHAR(255) email
        VARCHAR(255) password_hash
        VARCHAR(20) verification_status
        VARCHAR(255) verification_document_url
        VARCHAR(255) verification_social_url
        TIMESTAMP last_login
        VARCHAR(10) license_type
        TIMESTAMP license_expires_at
        VARCHAR(255) current_session_id
        TIMESTAMP created_at
        TIMESTAMP updated_at
    }

    user_profile {
        UUID user_id PK,FK
        VARCHAR(100) first_name
        VARCHAR(100) last_name
        DATE birth_date
        VARCHAR(2) country_code
        INT elo_rating
        INT open_elo_rating
        VARCHAR(255) profile_picture_url
        TEXT bio
        TIMESTAMP created_at
        TIMESTAMP updated_at
    }

    game_mode {
        UUID id PK
        VARCHAR(50) name
        TEXT description
        INT min_players
        INT max_players
        BOOLEAN is_team_mode
        JSONB rules
        TIMESTAMP created_at
    }

    organization {
        UUID id PK
        UUID parent_organization_id FK
        VARCHAR(255) name
        TEXT description
        VARCHAR(20) organization_type
        VARCHAR(2) country_code
        VARCHAR(100) region
        VARCHAR(20) verification_status
        VARCHAR(255) logo_url
        VARCHAR(255) website_url
        VARCHAR(255) contact_email
        UUID created_by FK
        TIMESTAMP created_at
        TIMESTAMP updated_at
    }

    organization_member {
        UUID user_id PK,FK
        UUID organization_id PK,FK
        VARCHAR(20) role
        BOOLEAN is_primary
        TIMESTAMP joined_at
    }

    tournament {
        UUID id PK
        UUID organization_id FK
        UUID game_mode_id FK
        VARCHAR(255) name
        TEXT description
        VARCHAR(50) tournament_type
        TIMESTAMP start_date
        TIMESTAMP end_date
        VARCHAR(255) location
        BOOLEAN is_official
        BOOLEAN is_official_approved
        UUID approved_by_organization_id FK
        VARCHAR(20) status
        INT points_per_round
        BOOLEAN is_cycles_mode
        INT rounds_planned
        JSONB ruleset
        DECIMAL(10,2) entry_fee
        DECIMAL(10,2) prize_pool
        BOOLEAN public_calendar
        UUID created_by FK
        TIMESTAMP created_at
        TIMESTAMP updated_at
    }

    tournament_participant {
        UUID tournament_id PK,FK
        UUID user_id PK,FK
        UUID partner_user_id FK
        VARCHAR(255) team_name
        INT initial_rating
        INT final_position
        TIMESTAMP created_at
    }

    tournament_round {
        UUID id PK
        UUID tournament_id FK
        INT round_number
        VARCHAR(20) status
        TIMESTAMP start_time
        TIMESTAMP end_time
        TIMESTAMP created_at
    }

    game {
        UUID id PK
        UUID round_id FK
        INT table_number
        UUID player1_id FK
        UUID player2_id FK
        UUID player3_id FK
        UUID player4_id FK
        INT team1_score
        INT team2_score
        VARCHAR(20) status
        TIMESTAMP start_time
        TIMESTAMP end_time
        UUID referee_id FK
        TIMESTAMP created_at
    }

    match_result {
        UUID game_id PK,FK
        UUID team1_player1_id FK
        UUID team1_player2_id FK
        UUID team2_player1_id FK
        UUID team2_player2_id FK
        INT team1_score
        INT team2_score
        BOOLEAN is_draw
        UUID reported_by FK
        UUID verified_by FK
        VARCHAR(20) verification_status
        TIMESTAMP created_at
        TIMESTAMP updated_at
    }

    tournament_ranking {
        UUID tournament_id PK,FK
        UUID user_id PK,FK
        INT position
        INT matches_played
        INT matches_won
        INT matches_lost
        INT matches_drawn
        INT total_points_for
        INT total_points_against
        DECIMAL(5,2) performance_rating
        DECIMAL(5,2) average_opponent_rating
        INT last_round_played
        TIMESTAMP updated_at
    }

    elo_history {
        UUID id PK
        UUID user_id FK
        VARCHAR(10) rating_type
        INT old_rating
        INT new_rating
        INT change
        UUID game_id FK
        UUID tournament_id FK
        VARCHAR(255) change_reason
        UUID changed_by FK
        TIMESTAMP created_at
    }

    global_ranking {
        UUID user_id PK,FK
        INT elo_rating
        INT open_elo_rating
        INT tournaments_played
        INT tournaments_won
        INT matches_played
        INT matches_won
        INT matches_lost
        INT matches_drawn
        INT total_points_for
        INT total_points_against
        DECIMAL(5,2) performance_rating
        TIMESTAMP last_tournament_date
        TIMESTAMP updated_at
    }

    regional_ranking {
        UUID user_id PK,FK
        VARCHAR(10) region_code PK
        INT elo_rating
        INT position
        TIMESTAMP updated_at
    }

    license_subscription {
        UUID id PK
        UUID user_id FK
        UUID organization_id FK
        VARCHAR(10) license_type
        VARCHAR(10) payment_plan
        TIMESTAMP start_date
        TIMESTAMP end_date
        BOOLEAN is_active
        DECIMAL(10,2) payment_amount
        VARCHAR(3) payment_currency
        VARCHAR(255) payment_receipt_url
        TIMESTAMP created_at
        TIMESTAMP updated_at
    }

    license_feature {
        VARCHAR(10) license_type PK
        INT max_organizations
        INT max_tournaments
        INT max_participants
        TEXT[] available_game_types
        BOOLEAN has_detailed_stats
        BOOLEAN allow_multiple_sessions
        BOOLEAN can_create_official_tournaments
        BOOLEAN can_verify_players
    }

    active_session {
        UUID id PK
        UUID user_id FK
        VARCHAR(255) session_token
        VARCHAR(45) ip_address
        TEXT user_agent
        TIMESTAMP created_at
        TIMESTAMP expires_at
    }

    notification {
        UUID id PK
        UUID user_id FK
        VARCHAR(255) title
        TEXT message
        BOOLEAN is_read
        VARCHAR(50) notification_type
        VARCHAR(50) related_entity_type
        UUID related_entity_id
        TIMESTAMP created_at
    }

    verification_request {
        UUID id PK
        UUID user_id FK
        UUID organization_id FK
        VARCHAR(50) request_type
        VARCHAR(20) status
        VARCHAR(255) document_url
        VARCHAR(255) social_verification_url
        UUID reviewed_by FK
        TEXT review_notes
        TIMESTAMP created_at
        TIMESTAMP updated_at
    }

    tournament_approval_request {
        UUID id PK
        UUID tournament_id FK
        UUID requesting_organization_id FK
        UUID approving_organization_id FK
        VARCHAR(20) status
        TIMESTAMP requested_at
        TIMESTAMP decided_at
        UUID decided_by FK
        TEXT notes
    }
