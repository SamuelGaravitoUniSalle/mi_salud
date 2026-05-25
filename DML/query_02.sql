-- ============================================================
--  CONSULTA 02 — ADULTOS MAYORES SIN ATENCIÓN MÉDICA REGISTRADA
--
--  Objetivo funcional:
--      Detectar afiliados de más de 50 años que estando ACTIVOS en
--      MiSalud NUNCA han tenido una cita atendida ni una HCE
--      registrada. Este grupo es candidato prioritario a
--      programas de captación y demanda inducida.
--
--  Indicador generado:
--      "Brecha de atención del adulto mayor (no contactados)"
--          - Lista nominal de pacientes de más de 50 años sin contacto clínico
--          - Edad, género y municipio de residencia
--          - Régimen al que pertenece (CNT vs SBS)
-- ============================================================
SET
      search_path TO misalud;

SELECT
      u.numero_documento AS documento,
      u.primer_nombre || ' ' || u.primer_apellido AS paciente,
      CAST(
            EXTRACT(
                  YEAR
                  FROM
                        AGE (u.fecha_nacimiento)
            ) AS INT
      ) AS edad,
      u.sexo,
      r.nombre AS regimen,
      m.nombre AS municipio,
      d.nombre AS departamento,
      u.telefono_celular AS contacto
FROM
      Usuario u
      LEFT JOIN Cita c ON c.id_usuario = u.id_usuario
      AND c.estado = 'ATENDIDA'
      INNER JOIN Municipio m ON m.id_municipio = u.id_municipio_residencia
      INNER JOIN Departamento d ON d.id_departamento = m.id_departamento
      INNER JOIN Regimen r ON r.id_regimen = u.id_regimen_actual
WHERE
      c.id_cita IS NULL
      AND u.estado_afiliacion = 'ACTIVO'
      AND EXTRACT(
            YEAR
            FROM
                  AGE (u.fecha_nacimiento)
      ) >= 50
      AND NOT EXISTS (
            SELECT
                  1
            FROM
                  Registro_Clinico rc
            WHERE
                  rc.id_usuario = u.id_usuario
      )
ORDER BY
      edad DESC,
      paciente;