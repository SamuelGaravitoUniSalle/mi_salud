-- =============================================================================
-- CONSULTA 08 - AUDITORIA DE HCE: CITAS ATENDIDAS SIN REGISTRO CLINICO
-- =============================================================================
-- Objetivo funcional:
--   Auditar el cumplimiento de la obligacion normativa de generar Historia
--   Clinica Electronica (HCE) por cada cita en estado ATENDIDA.
--
-- Indicador generado:
--   Listado de medicos con al menos una cita ATENDIDA sin HCE, junto con la
--   IPS donde ocurrio el hecho, para la apertura inmediata del proceso de
--   correccion o sancion administrativa. 
-- =============================================================================
SET
    search_path TO misalud;

SELECT
    m.numero_registro_medico AS registro_medico,
    m.primer_nombre || ' ' || m.primer_apellido AS medico,
    i.codigo_habilitacion AS codigo_ips,
    i.razon_social AS ips,
    COUNT(c.id_cita) AS citas_atendidas_sin_hce,
    MIN(c.fecha_cita) AS fecha_mas_antigua,
    MAX(c.fecha_cita) AS fecha_mas_reciente
FROM
    Medico m
    INNER JOIN Cita c ON c.id_medico = m.id_medico
    INNER JOIN Ips i ON i.id_ips = c.id_ips
WHERE
    EXISTS (
        SELECT
            1
        FROM
            Cita ce
        WHERE
            ce.id_medico = m.id_medico
            AND ce.estado = 'ATENDIDA'
    )
    AND c.estado = 'ATENDIDA'
    AND NOT EXISTS (
        SELECT
            1
        FROM
            Registro_Clinico rc
        WHERE
            rc.id_cita = c.id_cita
    )
GROUP BY
    m.numero_registro_medico,
    m.primer_nombre,
    m.primer_apellido,
    i.codigo_habilitacion,
    i.razon_social
ORDER BY
    citas_atendidas_sin_hce DESC,
    medico;