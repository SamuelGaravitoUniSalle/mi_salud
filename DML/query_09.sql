-- =============================================================================
-- CONSULTA 09 - IPS DE ALTA CAPACIDAD HABILITADAS EN ESPECIALIDADES CRITICAS
-- =============================================================================
-- Objetivo funcional:
--   Identificar las IPS que cumplen DOS condiciones simultaneas para ser
--   priorizadas en la asignacion del presupuesto de inversion 2026:
--     (1) Tener una capacidad instalada de camas SUPERIOR al promedio
--         nacional dentro del sistema MiSalud. 
--     (2) Estar habilitadas en al menos UNA de las TRES especialidades con
--         mayor demanda agendada en la plataforma.
--
-- Indicador generado:
--   Listado de IPS estrategicas (high-capacity + high-demand) para canalizar
--   inversiones de fortalecimiento de oferta. 
-- =============================================================================
SET
    search_path TO misalud;

SELECT
    i.codigo_habilitacion AS codigo_ips,
    i.razon_social AS ips,
    i.nivel_atencion AS nivel,
    i.capacidad_camas,
    i.capacidad_uci,
    m.nombre AS municipio,
    d.nombre AS departamento,
    COUNT(DISTINCT ie.id_especialidad) AS especialidades_top_habilitadas
FROM
    Ips i
    INNER JOIN Municipio m ON m.id_municipio = i.id_municipio
    INNER JOIN Departamento d ON d.id_departamento = m.id_departamento
    INNER JOIN Ips_Especialidad ie ON ie.id_ips = i.id_ips
WHERE
    i.capacidad_camas > (
        SELECT
            AVG(capacidad_camas)
        FROM
            Ips
        WHERE
            estado = 'ACTIVA'
            AND capacidad_camas IS NOT NULL
    )
    AND ie.id_especialidad IN (
        SELECT
            id_especialidad
        FROM
            (
                SELECT
                    id_especialidad,
                    COUNT(*) AS demanda
                FROM
                    Cita
                GROUP BY
                    id_especialidad
                ORDER BY
                    demanda DESC
                LIMIT
                    3
            ) AS top3
    )
    AND i.estado = 'ACTIVA'
GROUP BY
    i.codigo_habilitacion,
    i.razon_social,
    i.nivel_atencion,
    i.capacidad_camas,
    i.capacidad_uci,
    m.nombre,
    d.nombre
ORDER BY
    i.capacidad_camas DESC;