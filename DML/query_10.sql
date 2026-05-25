-- =============================================================================
-- CONSULTA 10 - VISTA GERENCIAL: DASHBOARD DEPARTAMENTAL DE OPERACION MISALUD
-- =============================================================================
-- Objetivo funcional:
--   Exponer como vista persistente  el tablero de control
--   departamental que consume la Direccion de Operaciones de MiSalud, con
--   el fin de monitorear semanalmente la cobertura, la productividad y la
--   calidad de la red prestadora a lo largo de los departamentos.
--
-- Indicador generado:
--   Por cada departamento del territorio nacional se exponen los siguientes
--   KPIs operacionales:
--     - ips_activas, medicos_activos, afiliados_activos
--     - citas_totales, citas_atendidas, citas_no_asistio, citas_canceladas
--     - pct_inasistencia      ("porcentaje")
--     - autorizaciones_pendientes 
--     - autorizaciones_negadas
-- =============================================================================
SET
    search_path TO misalud;

-- =============================================================================
-- CREACIÓN DE LA VISTA
-- =============================================================================
CREATE
OR REPLACE VIEW v_dashboard_gerencial AS
WITH
    oferta_ips AS (
        SELECT
            mu.id_departamento,
            COUNT(*) FILTER (
                WHERE
                    i.estado = 'ACTIVA'
            ) AS ips_activas
        FROM
            Ips i
            INNER JOIN Municipio mu ON mu.id_municipio = i.id_municipio
        GROUP BY
            mu.id_departamento
    ),
    oferta_medicos AS (
        SELECT
            mu.id_departamento,
            COUNT(DISTINCT mesp.id_medico) AS medicos_activos
        FROM
            Horario_Medico hm
            INNER JOIN Ips i ON i.id_ips = hm.id_ips
            INNER JOIN Municipio mu ON mu.id_municipio = i.id_municipio
            INNER JOIN Medico_Especialidad mesp ON mesp.id_medico_especialidad = hm.id_medico_especialidad
            INNER JOIN Medico me ON me.id_medico = mesp.id_medico
        WHERE
            hm.activo = TRUE
            AND me.activo = TRUE
        GROUP BY
            mu.id_departamento
    ),
    demanda_afiliados AS (
        SELECT
            mu.id_departamento,
            COUNT(*) FILTER (
                WHERE
                    u.estado_afiliacion = 'ACTIVO'
            ) AS afiliados_activos
        FROM
            Usuario u
            INNER JOIN Municipio mu ON mu.id_municipio = u.id_municipio_residencia
        GROUP BY
            mu.id_departamento
    ),
    operacion_citas AS (
        SELECT
            mu.id_departamento,
            COUNT(*) AS citas_totales,
            COUNT(*) FILTER (
                WHERE
                    c.estado = 'ATENDIDA'
            ) AS citas_atendidas,
            COUNT(*) FILTER (
                WHERE
                    c.estado = 'NO_ASISTIO'
            ) AS citas_no_asistio,
            COUNT(*) FILTER (
                WHERE
                    c.estado = 'CANCELADA'
            ) AS citas_canceladas
        FROM
            Cita c
            INNER JOIN Ips i ON i.id_ips = c.id_ips
            INNER JOIN Municipio mu ON mu.id_municipio = i.id_municipio
        GROUP BY
            mu.id_departamento
    ),
    operacion_auth AS (
        SELECT
            mu.id_departamento,
            COUNT(*) FILTER (
                WHERE
                    a.estado = 'PENDIENTE'
            ) AS autorizaciones_pendientes,
            COUNT(*) FILTER (
                WHERE
                    a.estado = 'NEGADA'
            ) AS autorizaciones_negadas
        FROM
            Autorizacion a
            INNER JOIN Ips i ON i.id_ips = a.id_ips_solicitante
            INNER JOIN Municipio mu ON mu.id_municipio = i.id_municipio
        GROUP BY
            mu.id_departamento
    )
SELECT
    d.codigo_dane AS cod_dane_dpto,
    d.nombre AS departamento,
    COALESCE(oi.ips_activas, 0) AS ips_activas,
    COALESCE(om.medicos_activos, 0) AS medicos_activos,
    COALESCE(da.afiliados_activos, 0) AS afiliados_activos,
    COALESCE(oc.citas_totales, 0) AS citas_totales,
    COALESCE(oc.citas_atendidas, 0) AS citas_atendidas,
    COALESCE(oc.citas_no_asistio, 0) AS citas_no_asistio,
    COALESCE(oc.citas_canceladas, 0) AS citas_canceladas,
    ROUND(
        100.0 * COALESCE(oc.citas_no_asistio, 0) / NULLIF(COALESCE(oc.citas_totales, 0), 0),
        2
    ) AS pct_inasistencia,
    COALESCE(oa.autorizaciones_pendientes, 0) AS autorizaciones_pendientes,
    COALESCE(oa.autorizaciones_negadas, 0) AS autorizaciones_negadas
FROM
    Departamento d
    LEFT JOIN oferta_ips oi ON oi.id_departamento = d.id_departamento
    LEFT JOIN oferta_medicos om ON om.id_departamento = d.id_departamento
    LEFT JOIN demanda_afiliados da ON da.id_departamento = d.id_departamento
    LEFT JOIN operacion_citas oc ON oc.id_departamento = d.id_departamento
    LEFT JOIN operacion_auth oa ON oa.id_departamento = d.id_departamento;

COMMENT ON VIEW v_dashboard_gerencial IS 'Tablero gerencial agregado por departamento: oferta, demanda y operacion. Insumo del informe semanal a la Direccion de Operaciones MiSalud.';

-- =============================================================================
-- VALIDACION FUNCIONAL DE LA VISTA
-- =============================================================================
SELECT
    departamento,
    ips_activas,
    medicos_activos,
    afiliados_activos,
    citas_totales,
    citas_atendidas,
    citas_no_asistio,
    pct_inasistencia,
    autorizaciones_pendientes,
    autorizaciones_negadas
FROM
    v_dashboard_gerencial
WHERE
    citas_totales > 0
    OR ips_activas > 0
ORDER BY
    citas_totales DESC,
    departamento;