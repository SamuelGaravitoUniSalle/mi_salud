-- =============================================================================
-- CONSULTA 06 - SEGMENTACION DE USUARIOS POR ADOPCION DE TELEMEDICINA
-- =============================================================================
-- Objetivo funcional:
--   Clasificar a los afiliados que han recibido al menos una atencion efectiva
--     - MULTICANAL: usuario con citas atendidas en PRESENCIAL Y TELEMEDICINA.
--     - SOLO_PRESENCIAL: usuario con citas atendidas unicamente en sede fisica.
--     - SOLO_TELEMEDICINA: usuario con citas atendidas unicamente por video.
--
-- Indicador generado:
--   Cohorte de adopcion de canales para el seguimiento de la transformacion
--   digital exigida por el Ministerio de Saludy la Politica de Atencion Integral 
--   en Salud.
-- =============================================================================
SET
    search_path TO misalud;

WITH
    cohorte_presencial AS (
        SELECT DISTINCT
            id_usuario
        FROM
            Cita
        WHERE
            estado = 'ATENDIDA'
            AND tipo_atencion = 'PRESENCIAL'
    ),
    cohorte_telemedicina AS (
        SELECT DISTINCT
            id_usuario
        FROM
            Cita
        WHERE
            estado = 'ATENDIDA'
            AND tipo_atencion = 'TELEMEDICINA'
    ),
    seg_multicanal AS (
        SELECT
            id_usuario,
            'MULTICANAL' AS segmento_canal
        FROM
            cohorte_presencial
        INTERSECT
        SELECT
            id_usuario,
            'MULTICANAL' AS segmento_canal
        FROM
            cohorte_telemedicina
    ),
    seg_solo_presencial AS (
        SELECT
            id_usuario,
            'SOLO_PRESENCIAL' AS segmento_canal
        FROM
            cohorte_presencial
        EXCEPT
        SELECT
            id_usuario,
            'SOLO_PRESENCIAL' AS segmento_canal
        FROM
            cohorte_telemedicina
    ),
    seg_solo_telemedicina AS (
        SELECT
            id_usuario,
            'SOLO_TELEMEDICINA' AS segmento_canal
        FROM
            cohorte_telemedicina
        EXCEPT
        SELECT
            id_usuario,
            'SOLO_TELEMEDICINA' AS segmento_canal
        FROM
            cohorte_presencial
    ),
    segmentacion AS (
        SELECT
            *
        FROM
            seg_multicanal
        UNION ALL
        SELECT
            *
        FROM
            seg_solo_presencial
        UNION ALL
        SELECT
            *
        FROM
            seg_solo_telemedicina
    )
SELECT
    s.segmento_canal,
    u.numero_documento,
    u.primer_nombre || ' ' || u.primer_apellido AS afiliado,
    CAST(
        DATE_PART ('year', AGE (u.fecha_nacimiento)) AS INT
    ) AS edad,
    e.codigo_habilitacion AS codigo_eps,
    e.razon_social AS eps
FROM
    segmentacion s
    INNER JOIN Usuario u ON u.id_usuario = s.id_usuario
    LEFT JOIN Eps e ON e.id_eps = u.id_eps_origen
ORDER BY
    s.segmento_canal,
    afiliado;