
-- ============================================================
--  MISALUD — Script DDL para PostgreSQL 15+
--  Plataforma Centralizada del Sistema de Salud Colombiano
-- ============================================================


CREATE SCHEMA IF NOT EXISTS misalud;
SET search_path TO misalud;

-- ============================================================
--  LIMPIEZA OPCIONAL (descomentar si se requiere recrear)
-- ============================================================
-- DROP TABLE IF EXISTS Autorizacion          CASCADE;
-- DROP TABLE IF EXISTS Registro_Clinico      CASCADE;
-- DROP TABLE IF EXISTS Cita                  CASCADE;
-- DROP TABLE IF EXISTS Procedimiento         CASCADE;
-- DROP TABLE IF EXISTS Usuario               CASCADE;
-- DROP TABLE IF EXISTS Horario_Medico        CASCADE;
-- DROP TABLE IF EXISTS Medico_Especialidad   CASCADE;
-- DROP TABLE IF EXISTS Medico                CASCADE;
-- DROP TABLE IF EXISTS Ips_Especialidad      CASCADE;
-- DROP TABLE IF EXISTS Ips                   CASCADE;
-- DROP TABLE IF EXISTS Eps                   CASCADE;
-- DROP TABLE IF EXISTS Regimen               CASCADE;
-- DROP TABLE IF EXISTS Especialidad          CASCADE;
-- DROP TABLE IF EXISTS Municipio             CASCADE;
-- DROP TABLE IF EXISTS Departamento          CASCADE;
-- DROP TABLE IF EXISTS Tipo_Documento        CASCADE;


-- ============================================================
--  01. TIPO_DOCUMENTO
-- ============================================================
CREATE TABLE Tipo_Documento (
    id_tipo_documento INTEGER      GENERATED ALWAYS AS IDENTITY,
    codigo            VARCHAR(5)   NOT NULL,
    descripcion       VARCHAR(100) NOT NULL,
    activo            BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT PK_TIPO_DOCUMENTO       PRIMARY KEY (id_tipo_documento),
    CONSTRAINT UQ_TIPO_DOCUMENTO_COD   UNIQUE (codigo)
);

COMMENT ON TABLE  Tipo_Documento              IS 'TABLA MAESTRA - Valores fijos según normativa RNEC (CC, CE, TI, PA, RC, PE, MS, AS, CD).';
COMMENT ON COLUMN Tipo_Documento.codigo       IS 'Código del tipo de documento: CC, CE, TI, PA, RC, PE, MS, AS, CD';
COMMENT ON COLUMN Tipo_Documento.descripcion  IS 'Ej: Cédula de Ciudadanía, Pasaporte';


-- ============================================================
--  02. DEPARTAMENTO
-- ============================================================
CREATE TABLE Departamento (
    id_departamento INTEGER      GENERATED ALWAYS AS IDENTITY,
    codigo_dane     CHAR(2)      NOT NULL,
    nombre          VARCHAR(100) NOT NULL,
    activo          BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT PK_DEPARTAMENTO     PRIMARY KEY (id_departamento),
    CONSTRAINT UQ_DEPARTAMENTO_DANE UNIQUE (codigo_dane)
);

CREATE INDEX IDX_DEPTO_DANE ON Departamento (codigo_dane);

COMMENT ON TABLE  Departamento             IS 'TABLA MAESTRA - DIVIPOLA (DANE). 33 registros base para Colombia.';
COMMENT ON COLUMN Departamento.codigo_dane IS 'Código DANE 2 dígitos. Ej: 11 (Bogotá), 05 (Antioquia)';


-- ============================================================
--  03. MUNICIPIO
-- ============================================================
CREATE TABLE Municipio (
    id_municipio        INTEGER      GENERATED ALWAYS AS IDENTITY,
    codigo_dane         CHAR(5)      NOT NULL,
    nombre              VARCHAR(100) NOT NULL,
    id_departamento     INTEGER      NOT NULL,
    categoria_municipio VARCHAR(10),
    zona                VARCHAR(10),
    activo              BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT PK_MUNICIPIO          PRIMARY KEY (id_municipio),
    CONSTRAINT UQ_MUNICIPIO_DANE     UNIQUE (codigo_dane),
    CONSTRAINT FK_MUNICIPIO_DEPTO
        FOREIGN KEY (id_departamento) REFERENCES Departamento(id_departamento),
    CONSTRAINT CK_MUNICIPIO_CATEGORIA
        CHECK (categoria_municipio IS NULL
               OR categoria_municipio IN ('ESPECIAL','1','2','3','4','5','6')),
    CONSTRAINT CK_MUNICIPIO_ZONA
        CHECK (zona IS NULL OR zona IN ('URBANA','RURAL','MIXTA'))
);

CREATE INDEX IDX_MUN_DANE  ON Municipio (codigo_dane);
CREATE INDEX IDX_MUN_DEPTO ON Municipio (id_departamento);

COMMENT ON TABLE  Municipio                     IS 'TABLA MAESTRA - DIVIPOLA (DANE). ~1.122 municipios.';
COMMENT ON COLUMN Municipio.codigo_dane         IS 'DIVIPOLA 5 dígitos = 2 depto + 3 municipio. Ej: 11001 (Bogotá)';
COMMENT ON COLUMN Municipio.categoria_municipio IS 'Categoría municipal según Ley 617/2000';


-- ============================================================
--  04. ESPECIALIDAD
-- ============================================================
CREATE TABLE Especialidad (
    id_especialidad   INTEGER      GENERATED ALWAYS AS IDENTITY,
    nombre            VARCHAR(150) NOT NULL,
    descripcion       VARCHAR(500),
    requiere_remision BOOLEAN      NOT NULL DEFAULT TRUE,
    nivel_complejidad INTEGER      NOT NULL DEFAULT 1,
    activo            BOOLEAN      NOT NULL DEFAULT TRUE,
    fecha_creacion    DATE         NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT PK_ESPECIALIDAD          PRIMARY KEY (id_especialidad),
    CONSTRAINT CK_ESPECIALIDAD_NIVEL    CHECK  (nivel_complejidad IN (1,2,3,4))
);

CREATE INDEX IDX_ESP_NOMBRE ON Especialidad (nombre);

COMMENT ON TABLE  Especialidad                   IS 'TABLA MAESTRA - Resolución 3100/2019 MSPS.';
COMMENT ON COLUMN Especialidad.requiere_remision IS 'TRUE/FALSE. Medicina General = FALSE';
COMMENT ON COLUMN Especialidad.nivel_complejidad IS 'Niveles de atención 1=básico a 4=alta complejidad';


-- ============================================================
--  05. REGIMEN
-- ============================================================
CREATE TABLE Regimen (
    id_regimen            INTEGER      GENERATED ALWAYS AS IDENTITY,
    codigo                VARCHAR(5)   NOT NULL,
    nombre                VARCHAR(100) NOT NULL,
    descripcion           VARCHAR(500),
    fuente_financiamiento VARCHAR(200),
    requiere_cotizacion   BOOLEAN      NOT NULL DEFAULT FALSE,
    activo                BOOLEAN      NOT NULL DEFAULT TRUE,
    CONSTRAINT PK_REGIMEN          PRIMARY KEY (id_regimen),
    CONSTRAINT UQ_REGIMEN_COD      UNIQUE (codigo)
);

COMMENT ON TABLE  Regimen                       IS 'TABLA MAESTRA - Regímenes del SGSSS (Ley 100/1993).';
COMMENT ON COLUMN Regimen.codigo                IS 'CNT (Contributivo), SBS (Subsidiado)';
COMMENT ON COLUMN Regimen.fuente_financiamiento IS 'Ej: PILA, Presupuesto Nacional, SISBEN IV, Fuerzas Militares';


-- ============================================================
--  06. EPS
-- ============================================================
CREATE TABLE Eps (
    id_eps                 INTEGER      GENERATED ALWAYS AS IDENTITY,
    codigo_habilitacion    VARCHAR(12)  NOT NULL,
    nit                    VARCHAR(15)  NOT NULL,
    razon_social           VARCHAR(200) NOT NULL,
    tipo_eps               VARCHAR(10)  NOT NULL,
    estado                 VARCHAR(15)  NOT NULL DEFAULT 'ACTIVA',
    nivel_endeudamiento    VARCHAR(10),
    total_afiliados        INTEGER      DEFAULT 0,
    telefono_contacto      VARCHAR(20),
    correo_contacto        VARCHAR(150),
    fecha_inicio_migracion DATE,
    fecha_fin_migracion    DATE,
    activo                 BOOLEAN      NOT NULL DEFAULT TRUE,
    fecha_creacion         DATE         NOT NULL DEFAULT CURRENT_DATE,
    usuario_creacion       VARCHAR(50)  NOT NULL,
    CONSTRAINT PK_EPS                PRIMARY KEY (id_eps),
    CONSTRAINT UQ_EPS_HABILITACION   UNIQUE (codigo_habilitacion),
    CONSTRAINT UQ_EPS_NIT            UNIQUE (nit),
    CONSTRAINT CK_EPS_TIPO           CHECK  (tipo_eps IN ('PUBLICA','PRIVADA','MIXTA')),
    CONSTRAINT CK_EPS_ESTADO         CHECK  (estado IN ('ACTIVA','INTERVENIDA','LIQUIDACION','LIQUIDADA')),
    CONSTRAINT CK_EPS_ENDEUDAMIENTO  CHECK  (nivel_endeudamiento IS NULL
                                             OR nivel_endeudamiento IN ('ALTO','MEDIO','BAJO','NA')),
    CONSTRAINT CK_EPS_AFILIADOS      CHECK  (total_afiliados >= 0),
    CONSTRAINT CK_EPS_FECHAS_MIGR    CHECK  (fecha_fin_migracion IS NULL
                                             OR fecha_inicio_migracion IS NULL
                                             OR fecha_fin_migracion >= fecha_inicio_migracion)
);

CREATE INDEX IDX_EPS_COD    ON Eps (codigo_habilitacion);
CREATE INDEX IDX_EPS_NIT    ON Eps (nit);
CREATE INDEX IDX_EPS_ESTADO ON Eps (estado);

COMMENT ON TABLE  Eps                        IS 'Hasta 46 EPS activas. Origen del proceso ETL hacia MiSalud.';
COMMENT ON COLUMN Eps.codigo_habilitacion    IS 'Código Superintendencia Nacional de Salud';
COMMENT ON COLUMN Eps.nit                    IS 'NIT sin dígito de verificación';
COMMENT ON COLUMN Eps.nivel_endeudamiento    IS 'Clasificación Supersalud para priorizar intervenciones';


-- ============================================================
--  07. IPS
-- ============================================================
CREATE TABLE Ips (
    id_ips              INTEGER      GENERATED ALWAYS AS IDENTITY,
    codigo_habilitacion VARCHAR(12)  NOT NULL,
    nit                 VARCHAR(15)  NOT NULL,
    razon_social        VARCHAR(200) NOT NULL,
    tipo_ips            VARCHAR(10)  NOT NULL,
    nivel_atencion      INTEGER      NOT NULL,
    id_municipio        INTEGER      NOT NULL,
    direccion           VARCHAR(300) NOT NULL,
    telefono_contacto   VARCHAR(20),
    correo_contacto     VARCHAR(150),
    capacidad_camas     INTEGER      DEFAULT 0,
    capacidad_uci       INTEGER      DEFAULT 0,
    estado              VARCHAR(15)  NOT NULL DEFAULT 'ACTIVA',
    activo              BOOLEAN      NOT NULL DEFAULT TRUE,
    fecha_habilitacion  DATE         NOT NULL,
    fecha_creacion      DATE         NOT NULL DEFAULT CURRENT_DATE,
    usuario_creacion    VARCHAR(50)  NOT NULL,
    CONSTRAINT PK_IPS                PRIMARY KEY (id_ips),
    CONSTRAINT UQ_IPS_HABILITACION   UNIQUE (codigo_habilitacion),
    CONSTRAINT UQ_IPS_NIT            UNIQUE (nit),
    CONSTRAINT FK_IPS_MUNICIPIO
        FOREIGN KEY (id_municipio) REFERENCES Municipio(id_municipio),
    CONSTRAINT CK_IPS_TIPO          CHECK (tipo_ips IN ('PUBLICA','PRIVADA','MIXTA')),
    CONSTRAINT CK_IPS_NIVEL         CHECK (nivel_atencion IN (1,2,3,4)),
    CONSTRAINT CK_IPS_CAMAS         CHECK (capacidad_camas >= 0),
    CONSTRAINT CK_IPS_UCI           CHECK (capacidad_uci >= 0),
    CONSTRAINT CK_IPS_ESTADO        CHECK (estado IN ('ACTIVA','SUSPENDIDA','INACTIVA'))
);

CREATE INDEX IDX_IPS_COD       ON Ips (codigo_habilitacion);
CREATE INDEX IDX_IPS_NIT       ON Ips (nit);
CREATE INDEX IDX_IPS_MUNICIPIO ON Ips (id_municipio);
CREATE INDEX IDX_IPS_NIVEL     ON Ips (nivel_atencion);
CREATE INDEX IDX_IPS_ESTADO    ON Ips (estado);

COMMENT ON TABLE  Ips                     IS '~13.000 IPS habilitadas en Colombia. Receptoras de Giro Directo ADRES.';
COMMENT ON COLUMN Ips.codigo_habilitacion IS 'Código REPS (Registro Especial de Prestadores de Salud)';
COMMENT ON COLUMN Ips.nivel_atencion      IS '1=básico, 4=alta complejidad - Resolución 3100/2019';
COMMENT ON COLUMN Ips.fecha_habilitacion  IS 'Fecha de habilitación oficial ante Supersalud / REPS';


-- ============================================================
--  08. IPS_ESPECIALIDAD 
-- ============================================================
CREATE TABLE Ips_Especialidad (
    id_ips_especialidad INTEGER GENERATED ALWAYS AS IDENTITY,
    id_ips              INTEGER NOT NULL,
    id_especialidad     INTEGER NOT NULL,
    activo              BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_actualizacion DATE    NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT PK_IPS_ESPECIALIDAD PRIMARY KEY (id_ips_especialidad),
    CONSTRAINT UQ_IPS_ESP          UNIQUE (id_ips, id_especialidad),
    CONSTRAINT FK_IPSESP_IPS
        FOREIGN KEY (id_ips) REFERENCES Ips(id_ips),
    CONSTRAINT FK_IPSESP_ESP
        FOREIGN KEY (id_especialidad) REFERENCES Especialidad(id_especialidad)
);

CREATE INDEX IDX_IPSEP_IPS ON Ips_Especialidad (id_ips);
CREATE INDEX IDX_IPSEP_ESP ON Ips_Especialidad (id_especialidad);

COMMENT ON TABLE Ips_Especialidad IS 'Tabla pivote N:M entre Ips y Especialidad.';


-- ============================================================
--  09. MEDICO  
-- ============================================================
CREATE TABLE Medico (
    id_medico              INTEGER      GENERATED ALWAYS AS IDENTITY,
    numero_registro_medico VARCHAR(20)  NOT NULL,
    id_tipo_documento      INTEGER      NOT NULL,
    numero_documento       VARCHAR(20)  NOT NULL,
    primer_nombre          VARCHAR(80)  NOT NULL,
    segundo_nombre         VARCHAR(80),
    primer_apellido        VARCHAR(80)  NOT NULL,
    segundo_apellido       VARCHAR(80),
    correo_institucional   VARCHAR(150) NOT NULL,
    telefono               VARCHAR(20),
    estado                 VARCHAR(15)  NOT NULL DEFAULT 'ACTIVO',
    activo                 BOOLEAN      NOT NULL DEFAULT TRUE,
    fecha_creacion         DATE         NOT NULL DEFAULT CURRENT_DATE,
    usuario_creacion       VARCHAR(50)  NOT NULL,
    CONSTRAINT PK_MEDICO              PRIMARY KEY (id_medico),
    CONSTRAINT UQ_MEDICO_RETHUS       UNIQUE (numero_registro_medico),
    CONSTRAINT UQ_MEDICO_CORREO       UNIQUE (correo_institucional),
    CONSTRAINT UQ_MED_DOC             UNIQUE (id_tipo_documento, numero_documento),
    CONSTRAINT FK_MEDICO_TIPO_DOC
        FOREIGN KEY (id_tipo_documento) REFERENCES Tipo_Documento(id_tipo_documento),
    CONSTRAINT CK_MEDICO_ESTADO       CHECK (estado IN ('ACTIVO','INACTIVO','SUSPENDIDO'))
);

CREATE INDEX IDX_MED_RETHUS ON Medico (numero_registro_medico);
CREATE INDEX IDX_MED_ESTADO ON Medico (estado);

COMMENT ON TABLE  Medico                        IS 'Integra con RETHUS del MSPS para validación de habilitación profesional.';
COMMENT ON COLUMN Medico.numero_registro_medico IS 'Registro RETHUS - MSPS. Obligatorio y único.';
COMMENT ON COLUMN Medico.correo_institucional   IS 'Correo MiSalud para notificaciones y autenticación';


-- ============================================================
--  10. MEDICO_ESPECIALIDAD
-- ============================================================
CREATE TABLE Medico_Especialidad (
    id_medico_especialidad INTEGER GENERATED ALWAYS AS IDENTITY,
    id_medico              INTEGER NOT NULL,
    id_especialidad        INTEGER NOT NULL,
    es_principal           BOOLEAN NOT NULL DEFAULT FALSE,
    activo                 BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT PK_MEDICO_ESPECIALIDAD PRIMARY KEY (id_medico_especialidad),
    CONSTRAINT UQ_MED_ESP             UNIQUE (id_medico, id_especialidad),
    CONSTRAINT FK_MEDESP_MED
        FOREIGN KEY (id_medico) REFERENCES Medico(id_medico),
    CONSTRAINT FK_MEDESP_ESP
        FOREIGN KEY (id_especialidad) REFERENCES Especialidad(id_especialidad)
);

CREATE INDEX IDX_MEDESP_MED ON Medico_Especialidad (id_medico);
CREATE INDEX IDX_MEDESP_ESP ON Medico_Especialidad (id_especialidad);

CREATE UNIQUE INDEX UQ_MEDESP_PRINCIPAL_UNICA
    ON Medico_Especialidad (id_medico)
    WHERE es_principal = TRUE AND activo = TRUE;

COMMENT ON TABLE Medico_Especialidad IS 'Tabla pivote N:M entre Medico y Especialidad. Garantiza 3FN.';


-- ============================================================
--  11. HORARIO_MEDICO
-- ============================================================
CREATE TABLE Horario_Medico (
    id_horario             INTEGER    GENERATED ALWAYS AS IDENTITY,
    id_medico_especialidad INTEGER    NOT NULL,
    id_ips                 INTEGER    NOT NULL,
    dia_semana             INTEGER    NOT NULL,
    hora_inicio            VARCHAR(5) NOT NULL,
    hora_fin               VARCHAR(5) NOT NULL,
    activo                 BOOLEAN    NOT NULL DEFAULT TRUE,
    CONSTRAINT PK_HORARIO_MEDICO    PRIMARY KEY (id_horario),
    CONSTRAINT FK_HORARIO_MEDESP
        FOREIGN KEY (id_medico_especialidad) REFERENCES Medico_Especialidad(id_medico_especialidad),
    CONSTRAINT FK_HORARIO_IPS
        FOREIGN KEY (id_ips) REFERENCES Ips(id_ips),
    CONSTRAINT CK_HORARIO_DIA       CHECK (dia_semana BETWEEN 1 AND 7),
    CONSTRAINT CK_HORARIO_FORMATO_INI
        CHECK (hora_inicio ~ '^([01][0-9]|2[0-3]):[0-5][0-9]$'),
    CONSTRAINT CK_HORARIO_FORMATO_FIN
        CHECK (hora_fin    ~ '^([01][0-9]|2[0-3]):[0-5][0-9]$'),
    CONSTRAINT CK_HORARIO_RANGO     CHECK (hora_fin > hora_inicio)
);

CREATE INDEX IDX_HOR_MEDICO ON Horario_Medico (id_medico_especialidad);
CREATE INDEX IDX_HOR_IPS    ON Horario_Medico (id_ips);

COMMENT ON TABLE  Horario_Medico            IS 'Disponibilidad semanal por médico, IPS y especialidad. Insumo del motor de agendamiento.';
COMMENT ON COLUMN Horario_Medico.dia_semana IS '1=Lunes, 7=Domingo';


-- ============================================================
--  12. USUARIO  (entidad central — ~53M registros)
-- ============================================================
CREATE TABLE Usuario (
    id_usuario               INTEGER      GENERATED ALWAYS AS IDENTITY,
    id_tipo_documento        INTEGER      NOT NULL,
    numero_documento         VARCHAR(20)  NOT NULL,
    primer_nombre            VARCHAR(80)  NOT NULL,
    segundo_nombre           VARCHAR(80),
    primer_apellido          VARCHAR(80)  NOT NULL,
    segundo_apellido         VARCHAR(80),
    fecha_nacimiento         DATE         NOT NULL,
    sexo                     CHAR(1)      NOT NULL,
    correo_electronico       VARCHAR(150),
    telefono_celular         VARCHAR(15),
    id_municipio_residencia  INTEGER      NOT NULL,
    direccion_residencia     VARCHAR(300),
    id_regimen_actual        INTEGER      NOT NULL,
    id_eps_origen            INTEGER,
    codigo_sisben            VARCHAR(20),
    puntaje_sisben           NUMERIC(5,2),
    estado_afiliacion        VARCHAR(15)  NOT NULL DEFAULT 'ACTIVO',
    fecha_afiliacion_misalud DATE         NOT NULL DEFAULT CURRENT_DATE,
    fecha_migracion          DATE,
    activo                   BOOLEAN      NOT NULL DEFAULT TRUE,
    fecha_creacion           DATE         NOT NULL DEFAULT CURRENT_DATE,
    usuario_creacion         VARCHAR(50)  NOT NULL,
    CONSTRAINT PK_USUARIO          PRIMARY KEY (id_usuario),
    CONSTRAINT UQ_USR_DOC          UNIQUE (id_tipo_documento, numero_documento),
    CONSTRAINT UQ_USR_EMAIL        UNIQUE (correo_electronico),
    CONSTRAINT FK_USUARIO_TIPO_DOC
        FOREIGN KEY (id_tipo_documento)        REFERENCES Tipo_Documento(id_tipo_documento),
    CONSTRAINT FK_USUARIO_MUNICIPIO
        FOREIGN KEY (id_municipio_residencia)  REFERENCES Municipio(id_municipio),
    CONSTRAINT FK_USUARIO_REGIMEN
        FOREIGN KEY (id_regimen_actual)        REFERENCES Regimen(id_regimen),
    CONSTRAINT FK_USUARIO_EPS
        FOREIGN KEY (id_eps_origen)            REFERENCES Eps(id_eps),
    CONSTRAINT CK_USUARIO_SEXO        CHECK (sexo IN ('M','F','I')),
    CONSTRAINT CK_USUARIO_SISBEN      CHECK (puntaje_sisben IS NULL
                                             OR (puntaje_sisben BETWEEN 0 AND 100)),
    CONSTRAINT CK_USUARIO_ESTADO_AFI  CHECK (estado_afiliacion IN ('ACTIVO','SUSPENDIDO','FALLECIDO','EMIGRADO')),
    CONSTRAINT CK_USUARIO_FECHA_NAC   CHECK (fecha_nacimiento <= CURRENT_DATE)
);

CREATE INDEX IDX_USR_REGIMEN   ON Usuario (id_regimen_actual);
CREATE INDEX IDX_USR_MUNICIPIO ON Usuario (id_municipio_residencia);
CREATE INDEX IDX_USR_ESTADO    ON Usuario (estado_afiliacion);
CREATE INDEX IDX_USR_EPS       ON Usuario (id_eps_origen);
CREATE INDEX IDX_USR_EMAIL     ON Usuario (correo_electronico);
CREATE INDEX IDX_USR_NACIM     ON Usuario (fecha_nacimiento);

COMMENT ON TABLE  Usuario                      IS 'ENTIDAD CENTRAL. ~53M registros. Datos personales protegidos por Ley 1581/2012.';
COMMENT ON COLUMN Usuario.sexo                 IS 'M, F o I (Indeterminado - Ley 1955/2019)';
COMMENT ON COLUMN Usuario.correo_electronico   IS 'Dato sensible - Ley 1581/2012';
COMMENT ON COLUMN Usuario.direccion_residencia IS 'Dato sensible - Ley 1581/2012';
COMMENT ON COLUMN Usuario.id_eps_origen        IS 'EPS de procedencia pre-migración. Trazabilidad ETL.';
COMMENT ON COLUMN Usuario.codigo_sisben        IS 'Obligatorio si régimen = SUBSIDIADO. Formato SISBEN IV.';


-- ============================================================
--  13. PROCEDIMIENTO
-- ============================================================
CREATE TABLE Procedimiento (
    id_procedimiento      INTEGER       GENERATED ALWAYS AS IDENTITY,
    codigo_cups           VARCHAR(10)   NOT NULL,
    nombre                VARCHAR(200)  NOT NULL,
    descripcion           VARCHAR(1000),
    id_especialidad       INTEGER,
    tipo_procedimiento    VARCHAR(15)   NOT NULL,
    requiere_autorizacion BOOLEAN       NOT NULL DEFAULT FALSE,
    nivel_complejidad     INTEGER,
    valor_upc_vigente     NUMERIC(15,2),
    activo                BOOLEAN       NOT NULL DEFAULT TRUE,
    fecha_creacion        DATE          NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT PK_PROCEDIMIENTO        PRIMARY KEY (id_procedimiento),
    CONSTRAINT UQ_PROCEDIMIENTO_CUPS   UNIQUE (codigo_cups),
    CONSTRAINT FK_PROC_ESP
        FOREIGN KEY (id_especialidad) REFERENCES Especialidad(id_especialidad),
    CONSTRAINT CK_PROC_TIPO            CHECK (tipo_procedimiento IN ('CONSULTA','DIAGNOSTICO','QUIRURGICO','TERAPEUTICO','OTRO')),
    CONSTRAINT CK_PROC_NIVEL           CHECK (nivel_complejidad IS NULL
                                              OR nivel_complejidad IN (1,2,3,4)),
    CONSTRAINT CK_PROC_VALOR           CHECK (valor_upc_vigente IS NULL
                                              OR valor_upc_vigente > 0)
);

CREATE INDEX IDX_PROC_CUPS ON Procedimiento (codigo_cups);
CREATE INDEX IDX_PROC_ESP  ON Procedimiento (id_especialidad);
CREATE INDEX IDX_PROC_TIPO ON Procedimiento (tipo_procedimiento);
CREATE INDEX IDX_PROC_AUTH ON Procedimiento (requiere_autorizacion);

COMMENT ON TABLE  Procedimiento                  IS 'Resolución 3512/2019 MSPS. Base para facturación a ADRES (Giro Directo).';
COMMENT ON COLUMN Procedimiento.codigo_cups      IS 'Clasificación CUPS - Resolución 3512/2019 MSPS';
COMMENT ON COLUMN Procedimiento.valor_upc_vigente IS 'Valor reconocido por ADRES (Giro Directo)';


-- ============================================================
--  14. CITA  (transaccional - > +200K inserciones/día)
-- ============================================================
CREATE TABLE Cita (
    id_cita            INTEGER      GENERATED ALWAYS AS IDENTITY,
    numero_cita        VARCHAR(25)  NOT NULL,
    id_usuario         INTEGER      NOT NULL,
    id_medico          INTEGER      NOT NULL,
    id_ips             INTEGER      NOT NULL,
    id_especialidad    INTEGER      NOT NULL,
    id_procedimiento   INTEGER,
    fecha_cita         DATE         NOT NULL,
    hora_inicio        VARCHAR(5)   NOT NULL,
    hora_fin           VARCHAR(5)   NOT NULL,
    tipo_atencion      VARCHAR(15)  NOT NULL DEFAULT 'PRESENCIAL',
    motivo_consulta    VARCHAR(500) NOT NULL,
    estado             VARCHAR(15)  NOT NULL DEFAULT 'AGENDADA',
    canal_agendamiento VARCHAR(15)  NOT NULL,
    es_urgencia        BOOLEAN      NOT NULL DEFAULT FALSE,
    id_cita_origen     INTEGER,
    observaciones      VARCHAR(1000),
    fecha_cancelacion  DATE,
    motivo_cancelacion VARCHAR(500),
    activo             BOOLEAN      NOT NULL DEFAULT TRUE,
    fecha_creacion     DATE         NOT NULL DEFAULT CURRENT_DATE,
    usuario_creacion   VARCHAR(50)  NOT NULL,
    CONSTRAINT PK_CITA            PRIMARY KEY (id_cita),
    CONSTRAINT UQ_CITA_NUMERO     UNIQUE (numero_cita),
    CONSTRAINT FK_CITA_USR
        FOREIGN KEY (id_usuario)       REFERENCES Usuario(id_usuario),
    CONSTRAINT FK_CITA_MED
        FOREIGN KEY (id_medico)        REFERENCES Medico(id_medico),
    CONSTRAINT FK_CITA_IPS
        FOREIGN KEY (id_ips)           REFERENCES Ips(id_ips),
    CONSTRAINT FK_CITA_ESP
        FOREIGN KEY (id_especialidad)  REFERENCES Especialidad(id_especialidad),
    CONSTRAINT FK_CITA_PROC
        FOREIGN KEY (id_procedimiento) REFERENCES Procedimiento(id_procedimiento),
    CONSTRAINT FK_CITA_ORIGEN
        FOREIGN KEY (id_cita_origen)   REFERENCES Cita(id_cita),
    CONSTRAINT CK_CITA_TIPO_ATENCION CHECK (tipo_atencion IN ('PRESENCIAL','TELEMEDICINA','DOMICILIARIA')),
    CONSTRAINT CK_CITA_ESTADO        CHECK (estado IN ('AGENDADA','CONFIRMADA','ATENDIDA','CANCELADA','NO_ASISTIO')),
    CONSTRAINT CK_CITA_CANAL         CHECK (canal_agendamiento IN ('APP','WEB','PRESENCIAL','TELEFONO')),
    CONSTRAINT CK_CITA_FORMATO_HI
        CHECK (hora_inicio ~ '^([01][0-9]|2[0-3]):[0-5][0-9]$'),
    CONSTRAINT CK_CITA_FORMATO_HF
        CHECK (hora_fin    ~ '^([01][0-9]|2[0-3]):[0-5][0-9]$'),
    CONSTRAINT CK_CITA_RANGO_HORA    CHECK (hora_fin > hora_inicio),
    CONSTRAINT CK_CITA_CANCELACION   CHECK (
        (fecha_cancelacion IS NULL  AND motivo_cancelacion IS NULL) OR
        (fecha_cancelacion IS NOT NULL AND motivo_cancelacion IS NOT NULL)
    )
);

CREATE INDEX IDX_CITA_NUM       ON Cita (numero_cita);
CREATE INDEX IDX_CITA_USR       ON Cita (id_usuario);
CREATE INDEX IDX_CITA_MED       ON Cita (id_medico);
CREATE INDEX IDX_CITA_IPS       ON Cita (id_ips);
CREATE INDEX IDX_CITA_MED_FECHA ON Cita (id_medico, fecha_cita);
CREATE INDEX IDX_CITA_USR_FECHA ON Cita (id_usuario, fecha_cita);
CREATE INDEX IDX_CITA_ESTADO    ON Cita (estado);
CREATE INDEX IDX_CITA_FECHA     ON Cita (fecha_cita);

COMMENT ON TABLE  Cita             IS 'TABLA TRANSACCIONAL DE ALTA CONCURRENCIA. Sugerido: PARTITION BY RANGE(fecha_cita).';
COMMENT ON COLUMN Cita.numero_cita IS 'Formato: MC-YYYYMMDD-XXXXXXXX';
COMMENT ON COLUMN Cita.id_cita_origen IS 'FK reflexiva - citas de seguimiento o remisión';

-- ============================================================
--  15. REGISTRO_CLINICO  (HCE — INMUTABLE: solo INSERT)
-- ============================================================
CREATE TABLE Registro_Clinico (
    id_registro              INTEGER       GENERATED ALWAYS AS IDENTITY,
    id_cita                  INTEGER       NOT NULL,
    id_usuario               INTEGER       NOT NULL,
    id_medico                INTEGER       NOT NULL,
    fecha_atencion           DATE          NOT NULL,
    motivo_consulta_ampliado VARCHAR(2000),
    anamnesis                TEXT,
    examen_fisico            TEXT,
    diagnostico_principal    VARCHAR(10)   NOT NULL,
    descripcion_diagnostico  VARCHAR(500),
    plan_tratamiento         TEXT,
    observaciones_medico     TEXT,
    requiere_hospitalizacion BOOLEAN       NOT NULL DEFAULT FALSE,
    requiere_remision        BOOLEAN       NOT NULL DEFAULT FALSE,
    id_especialidad_remision INTEGER,
    activo                   BOOLEAN       NOT NULL DEFAULT TRUE,
    fecha_creacion           DATE          NOT NULL DEFAULT CURRENT_DATE,
    usuario_creacion         VARCHAR(50)   NOT NULL,
    CONSTRAINT PK_REGISTRO_CLINICO    PRIMARY KEY (id_registro),
    CONSTRAINT UQ_RC_CITA             UNIQUE (id_cita), 
    CONSTRAINT FK_RC_CITA
        FOREIGN KEY (id_cita)                  REFERENCES Cita(id_cita),
    CONSTRAINT FK_RC_USR
        FOREIGN KEY (id_usuario)               REFERENCES Usuario(id_usuario),
    CONSTRAINT FK_RC_MED
        FOREIGN KEY (id_medico)                REFERENCES Medico(id_medico),
    CONSTRAINT FK_RC_ESP_REMISION
        FOREIGN KEY (id_especialidad_remision) REFERENCES Especialidad(id_especialidad),
    CONSTRAINT CK_RC_REMISION_ESP     CHECK (
        (NOT requiere_remision) OR
        (requiere_remision AND id_especialidad_remision IS NOT NULL)
    )
);

CREATE INDEX IDX_RC_CITA  ON Registro_Clinico (id_cita);
CREATE INDEX IDX_RC_USR   ON Registro_Clinico (id_usuario);
CREATE INDEX IDX_RC_MED   ON Registro_Clinico (id_medico);
CREATE INDEX IDX_RC_CIE10 ON Registro_Clinico (diagnostico_principal);
CREATE INDEX IDX_RC_FECHA ON Registro_Clinico (fecha_atencion);

COMMENT ON TABLE  Registro_Clinico                       IS 'HCE inmutable por ley (Res. 1995/1999). Solo INSERT, jamás DELETE ni UPDATE.';
COMMENT ON COLUMN Registro_Clinico.diagnostico_principal IS 'Código CIE-10';
COMMENT ON COLUMN Registro_Clinico.anamnesis             IS 'DATO SENSIBLE - cifrado AES-256 a nivel aplicación';
COMMENT ON COLUMN Registro_Clinico.examen_fisico         IS 'DATO SENSIBLE - cifrado AES-256';
COMMENT ON COLUMN Registro_Clinico.plan_tratamiento      IS 'DATO SENSIBLE - cifrado AES-256';

-- ------------------------------------------------------------
-- TRIGGER que bloquea UPDATE/DELETE sobre Registro_Clinico
-- (cumplimiento Resolución 1995/1999 MSPS)
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION fn_bloquear_modificacion_hce()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'Los registros clínicos son inmutables (Res. 1995/1999 MSPS). Operación % no permitida.', TG_OP;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_rc_no_update
BEFORE UPDATE ON Registro_Clinico
FOR EACH ROW EXECUTE FUNCTION fn_bloquear_modificacion_hce();

CREATE TRIGGER trg_rc_no_delete
BEFORE DELETE ON Registro_Clinico
FOR EACH ROW EXECUTE FUNCTION fn_bloquear_modificacion_hce();


-- ============================================================
--  16. AUTORIZACION
-- ============================================================
CREATE TABLE Autorizacion (
    id_autorizacion       INTEGER       GENERATED ALWAYS AS IDENTITY,
    numero_autorizacion   VARCHAR(25)   NOT NULL,
    id_usuario            INTEGER       NOT NULL,
    id_procedimiento      INTEGER       NOT NULL,
    id_ips_solicitante    INTEGER       NOT NULL,
    id_medico_solicitante INTEGER       NOT NULL,
    id_registro_clinico   INTEGER,
    justificacion_medica  TEXT          NOT NULL,
    estado                VARCHAR(15)   NOT NULL DEFAULT 'PENDIENTE',
    fecha_solicitud       DATE          NOT NULL DEFAULT CURRENT_DATE,
    fecha_respuesta       DATE,
    fecha_vencimiento     DATE,
    valor_autorizado      NUMERIC(15,2),
    observaciones_adres   VARCHAR(1000),
    activo                BOOLEAN       NOT NULL DEFAULT TRUE,
    usuario_creacion      VARCHAR(50)   NOT NULL,
    CONSTRAINT PK_AUTORIZACION       PRIMARY KEY (id_autorizacion),
    CONSTRAINT UQ_AUTH_NUMERO        UNIQUE (numero_autorizacion),
    CONSTRAINT FK_AUTH_USR
        FOREIGN KEY (id_usuario)            REFERENCES Usuario(id_usuario),
    CONSTRAINT FK_AUTH_PROC
        FOREIGN KEY (id_procedimiento)      REFERENCES Procedimiento(id_procedimiento),
    CONSTRAINT FK_AUTH_IPS
        FOREIGN KEY (id_ips_solicitante)    REFERENCES Ips(id_ips),
    CONSTRAINT FK_AUTH_MED
        FOREIGN KEY (id_medico_solicitante) REFERENCES Medico(id_medico),
    CONSTRAINT FK_AUTH_RC
        FOREIGN KEY (id_registro_clinico)   REFERENCES Registro_Clinico(id_registro),
    CONSTRAINT CK_AUTH_ESTADO        CHECK (estado IN ('PENDIENTE','APROBADA','NEGADA','APELADA','VENCIDA')),
    CONSTRAINT CK_AUTH_VALOR         CHECK (valor_autorizado IS NULL OR valor_autorizado >= 0),
    CONSTRAINT CK_AUTH_FECHAS        CHECK (
        fecha_respuesta IS NULL OR fecha_respuesta >= fecha_solicitud
    )
);

CREATE INDEX IDX_AUTH_NUM     ON Autorizacion (numero_autorizacion);
CREATE INDEX IDX_AUTH_USR     ON Autorizacion (id_usuario);
CREATE INDEX IDX_AUTH_ESTADO  ON Autorizacion (estado);
CREATE INDEX IDX_AUTH_USR_EST ON Autorizacion (id_usuario, estado);
CREATE INDEX IDX_AUTH_FECHA   ON Autorizacion (fecha_solicitud);
CREATE INDEX IDX_AUTH_IPS     ON Autorizacion (id_ips_solicitante);

COMMENT ON TABLE  Autorizacion                      IS 'SLA máximo 5 días hábiles según Resolución 3851/2016. Integra con sistema ADRES Giro Directo.';
COMMENT ON COLUMN Autorizacion.numero_autorizacion  IS 'Formato: AUTH-YYYYMMDD-XXXXXXXX';
COMMENT ON COLUMN Autorizacion.justificacion_medica IS 'DATO SENSIBLE - cifrado AES-256';
COMMENT ON COLUMN Autorizacion.valor_autorizado     IS 'Monto que ADRES girará directamente a la IPS';


