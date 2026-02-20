-- ============================================================
-- SCHEMA DE BASE DE DATOS - SISTEMA DE COMPARACION DE SEGUROS
-- ============================================================
-- Motor: PostgreSQL 14+
-- Modelo usado: Kimi k2.5 (estructuracion de datos relacionales)
-- ============================================================

-- Crear schema
CREATE SCHEMA IF NOT EXISTS seguros;

-- ============================================================
-- 1. TABLA: ASEGURADORAS
-- Catálogo de aseguradoras del mercado
-- ============================================================
CREATE TABLE seguros.aseguradoras (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    nombre_corto VARCHAR(20) NOT NULL,
    nit VARCHAR(20) UNIQUE,
    logo_url VARCHAR(255),
    activa BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO seguros.aseguradoras (nombre, nombre_corto) VALUES 
    ('Sura', 'SURA'),
    ('Allianz Colombia', 'ALLIANZ'),
    ('Liberty Seguros', 'LIBERTY'),
    ('Mapfre Colombia', 'MAPFRE'),
    ('Axa Colpatria', 'AXA'),
    ('HDI Seguros', 'HDI'),
    ('BBVA Seguros', 'BBVA'),
    ('Seguros del Estado', 'ESTADO'),
    ('Aseguradora Solidaria', 'SOLIDARIA'),
    ('Equidad Seguros', 'EQUIDAD');

-- ============================================================
-- 2. TABLA: RAMOS_DE_SEGURO
-- Catálogo de ramos soportados por el sistema
-- ============================================================
CREATE TABLE seguros.ramos (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(20) UNIQUE NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    activo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO seguros.ramos (codigo, nombre) VALUES
    ('TRDM', 'Todo Riesgo Danos Materiales'),
    ('RCG', 'Responsabilidad Civil General'),
    ('IRF', 'Manejo, Infidelidad y Riesgos Financieros'),
    ('DO', 'Responsabilidad Civil Directores y Administradores'),
    ('RCCH', 'Responsabilidad Civil Clinicas y Hospitales'),
    ('TV', 'Transporte de Valores'),
    ('TM', 'Transporte de Mercancias'),
    ('AP', 'Accidentes Personales'),
    ('AUTO', 'Automoviles'),
    ('VIDA', 'Seguro de Vida'),
    ('MYE', 'Maquinaria y Equipo'),
    ('CYBER', 'Cyber'),
    ('RPP', 'Recogida de Productos');

-- ============================================================
-- 3. TABLA: COBERTURAS_BASE
-- Catálogo de coberturas estándar por ramo (para homologación)
-- ============================================================
CREATE TABLE seguros.coberturas_base (
    id SERIAL PRIMARY KEY,
    ramo_id INTEGER REFERENCES seguros.ramos(id),
    nombre_estandar VARCHAR(100) NOT NULL,
    descripcion TEXT,
    sinonimos TEXT[], -- Array de nombres alternativos que pueden usar las aseguradoras
    categoria VARCHAR(50), -- 'principal', 'adicional', 'exclusion'
    es_obligatoria BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Ejemplo: Coberturas para TRDM
INSERT INTO seguros.coberturas_base (ramo_id, nombre_estandar, sinonimos, categoria) VALUES
    (1, 'Danos Materiales', ARRAY['Amparo de Bienes', 'Cobertura de Danos', 'Perdidas Materiales'], 'principal'),
    (1, 'Terremoto', ARRAY['Cobertura Sismica', 'Temblor', 'Catastrofe Natural'], 'principal'),
    (1, 'Responsabilidad Civil', ARRAY['RC', 'Responsabilidad Civil Extracontractual', 'Danos a Terceros'], 'principal'),
    (1, 'Equipo Electronico', ARRAY['Equipo de Computo', 'Tecnologico', 'Electronica'], 'adicional'),
    (1, 'Robo y Hurto', ARRAY['Hurto Calificado', 'Sustraccion', 'Robo con Violencia'], 'principal'),
    (1, 'Clausula de Estatus', ARRAY['Automatic Grant', 'Estatus Automatico', 'Automaticidad'], 'adicional');

-- ============================================================
-- 4. TABLA: CLAUSULADOS
-- Biblioteca de condiciones generales por aseguradora y ramo
-- ============================================================
CREATE TABLE seguros.clausulados (
    id SERIAL PRIMARY KEY,
    aseguradora_id INTEGER REFERENCES seguros.aseguradoras(id),
    ramo_id INTEGER REFERENCES seguros.ramos(id),
    version VARCHAR(20) NOT NULL, -- Ej: '2024-01'
    nombre_archivo VARCHAR(255) NOT NULL,
    path_archivo VARCHAR(500) NOT NULL,
    metadata JSONB, -- Info extraída del PDF
    activo BOOLEAN DEFAULT true,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(aseguradora_id, ramo_id, version)
);

-- ============================================================
-- 5. TABLA: COTIZACIONES
-- Registro maestro de cada cotización procesada
-- ============================================================
CREATE TABLE seguros.cotizaciones (
    id SERIAL PRIMARY KEY,
    cotizacion_id VARCHAR(50) UNIQUE NOT NULL, -- COT-20260220-001
    
    -- Relaciones
    cliente_nombre VARCHAR(200) NOT NULL,
    cliente_nit VARCHAR(20),
    cliente_sector VARCHAR(50), -- 'construccion', 'industria', 'comercio', etc.
    
    ramo_id INTEGER REFERENCES seguros.ramos(id),
    aseguradora_id INTEGER REFERENCES seguros.aseguradoras(id),
    
    -- Datos económicos
    prima_total DECIMAL(15,2),
    prima_iva_incluido DECIMAL(15,2),
    valor_asegurado DECIMAL(15,2),
    moneda VARCHAR(3) DEFAULT 'COP',
    
    -- Vigencia
    vigencia_desde DATE,
    vigencia_hasta DATE,
    
    -- Archivos
    pdf_path VARCHAR(500),
    pdf_hash VARCHAR(64), -- SHA256 para verificar duplicados
    
    -- Datos crudos extraídos por IA
    raw_data JSONB,
    
    -- Estado del procesamiento
    estado VARCHAR(20) DEFAULT 'procesando', -- 'procesando', 'completado', 'error', 'revision_manual'
    error_message TEXT,
    
    -- Metadata de extracción
    modelo_extraccion VARCHAR(50), -- 'gpt-4o', 'claude-3.5-sonnet'
    tokens_usados INTEGER,
    
    -- Auditoría
    ejecutivo_email VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices para búsquedas comunes
CREATE INDEX idx_cotizaciones_cliente ON seguros.cotizaciones(cliente_nombre);
CREATE INDEX idx_cotizaciones_ramo ON seguros.cotizaciones(ramo_id);
CREATE INDEX idx_cotizaciones_estado ON seguros.cotizaciones(estado);
CREATE INDEX idx_cotizaciones_fecha ON seguros.cotizaciones(created_at);

-- ============================================================
-- 6. TABLA: COBERTURAS_EXTRAIDAS
-- Detalle de cada cobertura encontrada en una cotización
-- ============================================================
CREATE TABLE seguros.coberturas_extraidas (
    id SERIAL PRIMARY KEY,
    cotizacion_id INTEGER REFERENCES seguros.cotizaciones(id) ON DELETE CASCADE,
    
    -- Relación con cobertura base (si se pudo homologar)
    cobertura_base_id INTEGER REFERENCES seguros.coberturas_base(id),
    
    -- Datos extraídos del PDF
    nombre_original VARCHAR(200) NOT NULL, -- Nombre como aparece en el PDF
    incluida BOOLEAN NOT NULL,
    sub_limite DECIMAL(15,2),
    deducible_porcentaje DECIMAL(5,2),
    deducible_minimo DECIMAL(15,2),
    observaciones TEXT,
    
    -- Referencia al clausulado
    clausulado_id INTEGER REFERENCES seguros.clausulados(id),
    pagina_referencia INTEGER,
    texto_clausula TEXT,
    
    -- Metadata
    confianza_extraccion DECIMAL(3,2), -- 0.00 a 1.00
    requiere_revision BOOLEAN DEFAULT false,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 7. TABLA: COMPARATIVOS
-- Agrupación de cotizaciones para un cliente/ramo específico
-- ============================================================
CREATE TABLE seguros.comparativos (
    id SERIAL PRIMARY KEY,
    comparativo_id VARCHAR(50) UNIQUE NOT NULL, -- CMP-20260220-001
    
    cliente_nombre VARCHAR(200) NOT NULL,
    ramo_id INTEGER REFERENCES seguros.ramos(id),
    
    -- Cotizaciones incluidas
    cotizacion_ids INTEGER[], -- Array de IDs de cotizaciones
    
    -- Resumen generado por IA
    resumen_json JSONB, -- Estructura con recomendaciones, alertas, etc.
    
    -- URLs de acceso
    url_publica VARCHAR(255),
    url_pdf_export VARCHAR(255),
    
    -- Estado
    estado VARCHAR(20) DEFAULT 'activo', -- 'activo', 'archivado', 'eliminado'
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 8. TABLA: EMBEDDINGS_COBERTURAS
-- Para el motor de homologación semántica (Vector DB)
-- Requiere extensión pgvector
-- ============================================================

-- CREATE EXTENSION IF NOT EXISTS vector; -- Descomentar si se usa pgvector

-- CREATE TABLE seguros.embeddings_coberturas (
--     id SERIAL PRIMARY KEY,
--     cobertura_base_id INTEGER REFERENCES seguros.coberturas_base(id),
--     texto_embedding TEXT NOT NULL,
--     embedding VECTOR(1536), -- Para OpenAI embeddings
--     modelo VARCHAR(50) DEFAULT 'text-embedding-3-small',
--     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
-- );

-- ============================================================
-- 9. VISTAS UTILES
-- ============================================================

-- Vista: Resumen de comparativo listo para frontend
CREATE OR REPLACE VIEW seguros.v_comparativos_resumen AS
SELECT 
    c.id,
    c.comparativo_id,
    c.cliente_nombre,
    r.nombre as ramo,
    c.cotizacion_ids,
    jsonb_pretty(c.resumen_json) as resumen,
    c.url_publica,
    c.created_at
FROM seguros.comparativos c
JOIN seguros.ramos r ON c.ramo_id = r.id;

-- Vista: Cotizaciones con info de aseguradora
CREATE OR REPLACE VIEW seguros.v_cotizaciones_completo AS
SELECT 
    c.*,
    a.nombre as aseguradora_nombre,
    a.nombre_corto as aseguradora_corto,
    r.nombre as ramo_nombre,
    r.codigo as ramo_codigo
FROM seguros.cotizaciones c
JOIN seguros.aseguradoras a ON c.aseguradora_id = a.id
JOIN seguros.ramos r ON c.ramo_id = r.id;

-- ============================================================
-- 10. FUNCIONES AUXILIARES
-- ============================================================

-- Función para actualizar timestamp
CREATE OR REPLACE FUNCTION seguros.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers para updated_at
CREATE TRIGGER tr_cotizaciones_updated_at
    BEFORE UPDATE ON seguros.cotizaciones
    FOR EACH ROW EXECUTE FUNCTION seguros.update_updated_at();

CREATE TRIGGER tr_comparativos_updated_at
    BEFORE UPDATE ON seguros.comparativos
    FOR EACH ROW EXECUTE FUNCTION seguros.update_updated_at();

-- Función: Crear nuevo comparativo desde cotizaciones
CREATE OR REPLACE FUNCTION seguros.crear_comparativo(
    p_cliente_nombre VARCHAR,
    p_ramo_id INTEGER,
    p_cotizacion_ids INTEGER[]
) RETURNS VARCHAR AS $$
DECLARE
    v_comparativo_id VARCHAR;
BEGIN
    v_comparativo_id := 'CMP-' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '-' || 
                        LPAD(NEXTVAL('seguros.comparativos_id_seq')::TEXT, 3, '0');
    
    INSERT INTO seguros.comparativos (comparativo_id, cliente_nombre, ramo_id, cotizacion_ids)
    VALUES (v_comparativo_id, p_cliente_nombre, p_ramo_id, p_cotizacion_ids);
    
    RETURN v_comparativo_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- EJEMPLOS DE USO
-- ============================================================

-- 1. Insertar una cotización
-- INSERT INTO seguros.cotizaciones (
--     cotizacion_id, cliente_nombre, ramo_id, aseguradora_id,
--     prima_total, valor_asegurado, pdf_path, raw_data, modelo_extraccion
-- ) VALUES (
--     'COT-20260220-001', 'Constructora Bogota S.A.', 1, 1,
--     45200000, 5000000000, '/data/cotizaciones/sura-001.pdf',
--     '{"coberturas": [...]}', 'gpt-4o'
-- );

-- 2. Crear comparativo
-- SELECT seguros.crear_comparativo('Constructora Bogota S.A.', 1, ARRAY[1, 2, 3, 4]);

-- 3. Consultar comparativo completo
-- SELECT * FROM seguros.v_comparativos_resumen WHERE comparativo_id = 'CMP-20260220-001';

-- ============================================================
-- NOTAS DE IMPLEMENTACION
-- ============================================================
-- 
-- 1. Para homologacion semantica avanzada, instalar pgvector:
--    CREATE EXTENSION vector;
--
-- 2. Para busqueda full-text en documentos:
--    CREATE INDEX idx_clausulados_fts ON seguros.clausulados 
--    USING gin(to_tsvector('spanish', metadata::text));
--
-- 3. Backup recomendado:
--    pg_dump -h localhost -U postgres -d aztec_seguros > backup.sql
--
-- 4. Modelos de IA usados en el sistema:
--    - Extraccion: GPT-4o (OpenAI) o Claude 3.5 Sonnet (Anthropic)
--    - Embeddings: text-embedding-3-small (OpenAI) o equivalente
--    - Homologacion: Similaridad coseno sobre vectores 1536-dim
--