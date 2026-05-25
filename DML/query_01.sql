-- ============================================================
--  CONSULTA 01 — TOP DE EPS POR AFILIADOS Y ACTIVIDAD ASISTENCIAL
--
--  Objetivo funcional:
--      Identificar las EPS con mayor volumen de afiliados activos
--      en MiSalud y cuantificar su actividad asistencial (citas)
--      para priorizar la atención del proceso ETL.
--
--  Indicador generado:
--      "Distribución de la carga asegurada en MiSalud"
--          - Número de afiliados activos por EPS
--          - Total de citas agendadas asociadas a esos afiliados
--      Permite a la mesa directiva enfocar recursos de migración
--      ETL en las EPS de mayor impacto poblacional.
-- ============================================================
SET
       search_path TO misalud;

SELECT
       e.razon_social AS eps,
       e.tipo_eps AS tipo,
       e.estado AS estado_eps,
       COUNT(DISTINCT u.id_usuario) AS afiliados_activos,
       COUNT(c.id_cita) AS total_citas,
       MIN(u.fecha_afiliacion_misalud) AS primera_afiliacion,
       MAX(u.fecha_afiliacion_misalud) AS ultima_afiliacion
FROM
       Eps e
       INNER JOIN Usuario u ON u.id_eps_origen = e.id_eps
       AND u.estado_afiliacion = 'ACTIVO'
       LEFT JOIN Cita c ON c.id_usuario = u.id_usuario
GROUP BY
       e.id_eps,
       e.razon_social,
       e.tipo_eps,
       e.estado
HAVING
       COUNT(DISTINCT u.id_usuario) > 0
ORDER BY
       afiliados_activos DESC,
       total_citas DESC
LIMIT
       10;