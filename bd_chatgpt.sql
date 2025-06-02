-- Tabla para las modalidades de juego  
CREATE TABLE modalidades (  
    id SERIAL PRIMARY KEY,  
    nombre TEXT NOT NULL UNIQUE  
);  
  
-- Tabla para las federaciones  
CREATE TABLE federaciones (  
    id SERIAL PRIMARY KEY,  
    nombre TEXT NOT NULL,  
    pais TEXT NOT NULL,  
    estado TEXT,  
    aprobado BOOLEAN DEFAULT FALSE,  
    fecha_registro TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,  
    verificado BOOLEAN DEFAULT FALSE,  
    social_verification JSONB,  
    documentos_verificacion JSONB  
);  
  
-- Tabla para las asociaciones  
CREATE TABLE asociaciones (  
    id SERIAL PRIMARY KEY,  
    federacion_id INT8 REFERENCES federaciones(id),  
    nombre TEXT NOT NULL,  
    pais TEXT,  
    estado TEXT,  
    aprobado BOOLEAN DEFAULT FALSE,  
    fecha_registro TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,  
    verificado BOOLEAN DEFAULT FALSE,  
    social_verification JSONB,  
    documentos_verificacion JSONB  
);  
  
-- Tabla para los clubes  
CREATE TABLE clubes (  
    id SERIAL PRIMARY KEY,  
    asociacion_id INT8 REFERENCES asociaciones(id),  
    nombre TEXT NOT NULL,  
    pais TEXT,  
    estado TEXT,  
    aprobado BOOLEAN DEFAULT FALSE,  
    verificado BOOLEAN DEFAULT FALSE,  
    fecha_registro TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,  
    social_verification JSONB,  
    documentos_verificacion JSONB  
);  
  
-- Tabla para los usuarios  
CREATE TABLE usuarios (  
    id SERIAL PRIMARY KEY,  
    nombre TEXT NOT NULL,  
    email TEXT UNIQUE NOT NULL,  
    password_hash TEXT NOT NULL,  
    rol TEXT NOT NULL, -- 'jugador', 'arbitro', 'administrador', 'aficionado'  
    tipo_licencia TEXT, -- 'basica', 'premium'  
    estado_sesion BOOLEAN DEFAULT FALSE,  
    ip_registro TEXT,  
    navegador TEXT,  
    fecha_registro TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,  
    verificado BOOLEAN DEFAULT FALSE,  
    afiliacion_tipo TEXT, -- 'federacion', 'asociacion', 'club', 'aficionado'  
    afiliacion_id INT8,  
    licencia_activa BOOLEAN DEFAULT FALSE  
);  
  
-- Tabla para las licencias  
CREATE TABLE licencias (  
    id SERIAL PRIMARY KEY,  
    usuario_id INT8 REFERENCES usuarios(id),  
    tipo TEXT, -- 'basica', 'premium'  
    fecha_inicio TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,  
    fecha_vencimiento TIMESTAMPTZ,  
    cantidad_torneos_organizados INT DEFAULT 0,  
    permisos JSONB  
);  
  
-- Tabla para los torneos  
CREATE TABLE torneos (  
    id SERIAL PRIMARY KEY,  
    nombre TEXT NOT NULL,  
    organizador_id INT8 REFERENCES usuarios(id),  
    modalidad_id INT8 REFERENCES modalidades(id),  
    numero_rondas INT CHECK (numero_rondas BETWEEN 5 AND 12),  
    fecha_inicio TIMESTAMPTZ,  
    fecha_fin TIMESTAMPTZ,  
    descripcion TEXT,  
    estado TEXT DEFAULT 'programado' -- 'programado', 'en curso', 'finalizado'  
);  
  
-- Tabla para las rondas de los torneos  
CREATE TABLE rondas (  
    id SERIAL PRIMARY KEY,  
    torneo_id INT8 REFERENCES torneos(id),  
    numero_ronda INT NOT NULL,  
    tipo_ciclo TEXT, -- '200 puntos', '100 puntos', 'ciclo'  
    cantidad_puntos INT CHECK (cantidad_puntos IN (100, 200)),  
    fecha TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP  
);  
  
-- Tabla para las partidas  
CREATE TABLE partidas (  
    id SERIAL PRIMARY KEY,  
    ronda_id INT8 REFERENCES rondas(id),  
    pareja1_id INT8 REFERENCES usuarios(id),  
    pareja2_id INT8 REFERENCES usuarios(id),  
    puntos_favor INT,  
    puntos_contra INT,  
    resultado TEXT, -- 'ganado', 'perdido', 'empatado'  
    fecha TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP  
);  
  
-- Tabla para la clasificación de los torneos  
CREATE TABLE clasificacion (  
    id SERIAL PRIMARY KEY,  
    torneo_id INT8 REFERENCES torneos(id),  
    jugador_id INT8 REFERENCES usuarios(id),  
    posicion INT,  
    puntos INT,  
    estadisticas JSONB -- Para almacenar los índices estadísticos  
);  
  
-- Tabla para la clasificación universal  
CREATE TABLE clasificacion_universal (  
    id SERIAL PRIMARY KEY,  
    jugador_id INT8 REFERENCES usuarios(id),  
    elo DECIMAL(10, 2),  
    region TEXT,  
    pais TEXT,  
    fecha_actualizacion TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP  
);  
  
-- Tabla para los avales de torneos  
CREATE TABLE avales (  
    id SERIAL PRIMARY KEY,  
    torneo_id INT8 REFERENCES torneos(id),  
    instancia_superior_id INT8 REFERENCES federaciones(id), -- Puede ser una federación o asociación  
    estado TEXT, -- 'pendiente', 'aprobado', 'rechazado'  
    fecha_solicitud TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,  
    fecha_aprobacion TIMESTAMPTZ  
);  
  
-- Tabla para los eventos públicos  
CREATE TABLE eventos (  
    id SERIAL PRIMARY KEY,  
    organizador_id INT8 REFERENCES usuarios(id),  
    nombre TEXT NOT NULL,  
    descripcion TEXT,  
    fecha TIMESTAMPTZ,  
    hora TIME,  
    costo DECIMAL(10, 2),  
    premio DECIMAL(10, 2),  
    ubicacion TEXT,  
    tipo TEXT -- 'torneo', 'evento social', etc.  
);  
