-- =============================================================================
-- CONSULTA 07 - ESPECIALIDADES RESOLUTIVAS SIN PROCEDIMIENTOS AUTORIZADOS
-- =============================================================================
-- Objetivo funcional:
--   Identificar las especialidades en las que se han agendado y/o atendido
--   citas pero para las que el modulo de autorizaciones NO ha generado todavia
--   ningun tramite (ni APROBADA, NEGADA, PENDIENTE ni VENCIDA). Esto sugiere
--   que la atencion se esta resolviendo en el primer encuentro o, 
--   alternativamente, que existe una brecha de registro en el proceso de autorizacion.
--
-- Indicador generado:
--   Lista nominal de especialidades resolutivas más eñ volumen de citas que las
--   respaldan, insumo para los Comites Tecnico-Cientificos de cada IPS. 
-- =============================================================================
SET
    search_path TO misalud;

SELECT
    e.id_especialidad,
    e.nombre AS especialidad,
    e.nivel_complejidad AS nivel,
    e.requiere_remision,
    COUNT(c.id_cita) AS total_citas,
    COUNT(*) FILTER (
        WHERE
            c.estado = 'ATENDIDA'
    ) AS citas_atendidas,
    COUNT(*) FILTER (
        WHERE
            c.estado = 'NO_ASISTIO'
    ) AS citas_no_asistio
FROM
    Especialidad e
    INNER JOIN Cita c ON c.id_especialidad = e.id_especialidad
WHERE
    e.id_especialidad IN (
        SELECT DISTINCT
            id_especialidad
        FROM
            Cita
        EXCEPT
        SELECT DISTINCT
            p.id_especialidad
        FROM
            Autorizacion a
            INNER JOIN Procedimiento p ON p.id_procedimiento = a.id_procedimiento
    )
GROUP BY
    e.id_especialidad,
    e.nombre,
    e.nivel_complejidad,
    e.requiere_remision
ORDER BY
    total_citas DESC,
    especialidad;