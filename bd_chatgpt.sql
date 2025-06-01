-- Tabla para registrar las federaciones internacionales  
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
  
-- Tabla para registrar las asociaciones nacionales o regionales  
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
  
-- Tabla para registrar clubes  
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
  
-- Tabla para registrar moderadores autorizados  
CREATE TABLE moderadores (  
    id SERIAL PRIMARY KEY,  
    federacion_id INT8 REFERENCES federaciones(id),  
    asociacion_id INT8 REFERENCES asociaciones(id),  
    club_id INT8 REFERENCES clubes(id),  
    nombre TEXT NOT NULL,  
    email TEXT UNIQUE NOT NULL,  
    verificado BOOLEAN DEFAULT FALSE,  
    social_verification JSONB,  
    documentos_verificacion JSONB,  
    fecha_registro TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP  
);  
  
-- Tabla para registrar usuarios (jugadores, árbitros, aficionados)  
CREATE TABLE usuarios (  
    id SERIAL PRIMARY KEY,  
    nombre TEXT NOT NULL,  
    email TEXT UNIQUE NOT NULL,  
    password_hash TEXT NOT NULL,  
    rol TEXT NOT NULL, -- 'jugador', 'arbitro', 'aficionado'  
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
  
-- Tabla para registrar licencias  
CREATE TABLE licencias (  
    id SERIAL PRIMARY KEY,  
    usuario_id INT8 REFERENCES usuarios(id),  
    tipo TEXT, -- 'basica', 'premium'  
    modalidad TEXT,  
    fecha_inicio TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,  
    fecha_fin TIMESTAMPTZ,  
    pago_mensual BOOLEAN DEFAULT TRUE,  
    estado TEXT DEFAULT 'activa', -- 'activa', 'caducada', 'cancelada'  
    costo DECIMAL(10,2)  
);  
  
-- Tabla para registrar sesiones abiertas  
CREATE TABLE sesiones (  
    id SERIAL PRIMARY KEY,  
    usuario_id INT8 REFERENCES usuarios(id),  
    ip TEXT,  
    navegador TEXT,  
    fecha_inicio TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,  
    fecha_cierre TIMESTAMPTZ,  
    sesion_activa BOOLEAN DEFAULT TRUE  
);  
  
-- Tabla para registrar rankings oficiales y abiertos  
CREATE TABLE rankings (  
    id SERIAL PRIMARY KEY,  
    nombre TEXT,  
    tipo TEXT, -- 'oficial', 'abierto'  
    categoria TEXT,  
    fecha_creacion TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,  
    descripcion TEXT  
);  
  
-- Tabla para registrar resultados de torneos  
CREATE TABLE resultados (  
    id SERIAL PRIMARY KEY,  
    torneo_id INT8 REFERENCES torneos(id),  
    jugador_id INT8 REFERENCES usuarios(id),  
    resultado TEXT,  
    fecha TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP  
);  
  
-- Tabla para registrar torneos  
CREATE TABLE torneos (  
    id SERIAL PRIMARY KEY,  
    nombre TEXT,  
    modalidad TEXT,  
    fecha_inicio TIMESTAMPTZ,  
    fecha_fin TIMESTAMPTZ,  
    sistema TEXT, -- 'suizo', etc.  
    ranking_id INT8 REFERENCES rankings(id),  
    estado TEXT DEFAULT 'programado'  
);  
  
-- Tabla para registrar licencias de venta  
CREATE TABLE ventas_licencias (  
    id SERIAL PRIMARY KEY,  
    licencia_id INT8 REFERENCES licencias(id),  
    comprador_id INT8 REFERENCES usuarios(id),  
    fecha_compra TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,  
    monto DECIMAL(10,2),  
    periodo TEXT -- 'mensual', 'anual'  
);  
  
-- Tabla para registrar pagos  
CREATE TABLE pagos (  
    id SERIAL PRIMARY KEY,  
    usuario_id INT8 REFERENCES usuarios(id),  
    monto DECIMAL(10,2),  
    fecha_pago TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,  
    metodo_pago TEXT,  
    estado TEXT -- 'completado', 'pendiente', 'fallido'  
);  
