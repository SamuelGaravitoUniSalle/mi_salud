-- ============================================================
--  CONSULTA 05 — DENSIDAD DE PROFESIONALES POR ESPECIALIDAD
--                Y NIVEL DE COMPLEJIDAD
--
--  Objetivo funcional:
--      Cuantificar la cantidad de médicos activos por
--      especialidad y nivel de complejidad, distinguiendo
--      quiénes la tienen como area principal versus
--      subespecializaciones secundarias. Esto soporta
--      el cierre de brechas de talento humano frente a la
--      demanda registrada en MiSalud.
--
--  Indicador generado:
--      "Disponibilidad de talento humano clínico"
--          - Médicos activos por especialidad
--          - Médicos cuya práctica principal es esa especialidad
--          - Distribución por nivel de complejidad
--      Apoya la planeación y los acuerdos de
--      formación con universidades.
-- ============================================================
SET
    search_path TO misalud;

WITH
    med AS (
        SELECT
            id_medico,
            primer_nombre,
            primer_apellido,
            numero_registro_medico
        FROM
            Medico
        WHERE
            estado = 'ACTIVO'
            AND activo = TRUE
    ),
    med_esp AS (
        SELECT
            id_medico,
            id_especialidad,
            es_principal
        FROM
            Medico_Especialidad
        WHERE
            activo = TRUE
    ),
    esp AS (
        SELECT
            id_especialidad,
            nombre AS especialidad,
            nivel_complejidad,
            requiere_remision
        FROM
            Especialidad
        WHERE
            activo = TRUE
    )
SELECT
    nivel_complejidad AS nivel,
    especialidad,
    requiere_remision AS requiere_remision,
    COUNT(DISTINCT id_medico) AS total_medicos,
    COUNT(*) FILTER (
        WHERE
            es_principal
    ) AS medicos_principal,
    COUNT(*) FILTER (
        WHERE
            NOT es_principal
    ) AS medicos_secundaria
FROM
    med
    NATURAL JOIN med_esp
    NATURAL JOIN esp
GROUP BY
    nivel_complejidad,
    especialidad,
    requiere_remision
ORDER BY
    nivel_complejidad DESC,
    total_medicos DESC,
    especialidad;