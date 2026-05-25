-- ============================================================
--  CONSULTA 04 — MATRIZ DE DISPONIBILIDAD HORARIA POR IPS Y DÍA
--
--  Objetivo funcional:
--      Construir la matriz IPS × Día-de-la-semana para
--      las prestadoras de alta complejidad y contrastarla con
--      la disponibilidad real configurada en MiSalud. 
--
--  Indicador generado:
--      "Densidad horaria por IPS y día de la semana"
--          - Bloques de horario activos por IPS y día
--          - Total de horas disponibles
--          - Días sin oferta
--      Permite detectar capacidad ociosa y días críticos de
--      saturación en cada IPS.
-- ============================================================
SET
    search_path TO misalud;

WITH
    dias_semana (dia, nombre) AS (
        VALUES
            (1, 'LUNES'),
            (2, 'MARTES'),
            (3, 'MIERCOLES'),
            (4, 'JUEVES'),
            (5, 'VIERNES'),
            (6, 'SABADO'),
            (7, 'DOMINGO')
    )
SELECT
    i.razon_social AS ips,
    i.nivel_atencion AS nivel,
    ds.dia AS num_dia,
    ds.nombre AS dia_semana,
    COUNT(h.id_horario) AS bloques_configurados,
    CAST(
        COALESCE(
            SUM(
                EXTRACT(
                    EPOCH
                    FROM
                        (
                            CAST(h.hora_fin AS TIME) - CAST(h.hora_inicio AS TIME)
                        )
                ) / 3600.0
            ),
            0
        ) AS NUMERIC(6, 1)
    ) AS horas_disponibles,
    CASE
        WHEN COUNT(h.id_horario) = 0 THEN 'SIN OFERTA'
        ELSE 'OPERATIVO'
    END AS estado_dia
FROM
    Ips i
    CROSS JOIN dias_semana ds
    LEFT JOIN Horario_Medico h ON h.id_ips = i.id_ips
    AND h.dia_semana = ds.dia
    AND h.activo = TRUE
WHERE
    i.nivel_atencion >= 2
    AND i.estado = 'ACTIVA'
GROUP BY
    i.id_ips,
    i.razon_social,
    i.nivel_atencion,
    ds.dia,
    ds.nombre
ORDER BY
    i.razon_social,
    ds.dia;