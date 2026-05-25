-- ============================================================
--  CONSULTA 03 — COBERTURA TERRITORIAL DE IPS POR DEPARTAMENTO
--
--  Objetivo funcional:
--      Cuantificar la oferta hospitalaria por departamento,
--      incluyendo aquellos que NO cuentan con IPS registradas
--      en MiSalud. Permite que el Ministerio priorice la 
--      habilitación de nuevos prestadores en zonas de baja cobertura.
--
--  Indicador generado:
--      "Cobertura de la red prestadora a nivel territorial"
--          - Total de IPS por departamento
--          - IPS de alta complejidad (nivel 3 y 4)
--          - Suma de camas hospitalarias y UCI por departamento
--          - Capacidad MÁXIMA y MÍNIMA en una sola IPS
--      Departamentos con cero IPS en ellos hay brecha estructural para
--      reportar a la Superintendencia Nacional de Salud.
-- ============================================================
SET
       search_path TO misalud;

SELECT
       d.codigo_dane AS cod_depto,
       d.nombre AS departamento,
       COUNT(DISTINCT i.id_ips) AS total_ips,
       COUNT(
              DISTINCT CASE
                     WHEN i.nivel_atencion >= 3 THEN i.id_ips
              END
       ) AS ips_alta_complejidad,
       COALESCE(SUM(i.capacidad_camas), 0) AS camas_totales,
       COALESCE(SUM(i.capacidad_uci), 0) AS camas_uci_totales,
       COALESCE(MAX(i.capacidad_camas), 0) AS max_camas_una_ips,
       COALESCE(MIN(i.capacidad_camas), 0) AS min_camas_una_ips
FROM
       Ips i
       INNER JOIN Municipio m ON m.id_municipio = i.id_municipio
       RIGHT JOIN Departamento d ON d.id_departamento = m.id_departamento
GROUP BY
       d.codigo_dane,
       d.nombre
ORDER BY
       total_ips DESC,
       camas_totales DESC,
       d.nombre;