# MiSalud - DML


Este paquete contiene tanto los scripts de poblamiento de la base de datos `mi_salud` como las 10 consultas SQL desarrolladas para la generación de indicadores de negocio.

---

## Descripción de indicadores

| Archivo                  | Tipo            | Proposito principal                                                                 |
|--------------------------|-----------------|-------------------------------------------------------------------------------------|
| `populate_database.sql`      | DML             | Realiza el poblamiento de la base de datos.      |
| `query_01.sql`        | Reporte         | Ranking de EPS por afiliados y volumen de citas.                                    |
| `query_02.sql`        | Gestion clinica | Adultos mayores sin atencion registrada en MiSalud.           |
| `query_03.sql`        | Cobertura       | Cobertura territorial de IPS por departamento.|
| `query_04.sql`        | Programacion    | Matriz IPS x dia de la semana con disponibilidad y saturacion.                      |
| `query_05.sql`        | Talento humano  | Distribucion de medicos por especialidad.                 |
| `query_06.sql`        | Transformacion  | Segmentacion de afiliados por adopcion de telemedicina.       |
| `query_07.sql`        | Calidad         | Especialidades con citas pero sin autorizaciones (resolutivas o brecha).            |
| `query_08.sql`        | Auditoria       | Citas atendidas sin HCE -incumplimiento Res. 1995/1999 y Res. 839/2017.            |
| `query_09.sql`        | Inversion       | IPS de alta capacidad habilitadas en las TOP-3 especialidades mas demandadas.       |
| `query_10.sql`        | Gerencia        | `VIEW` `v_dashboard_gerencial` -tablero KPI por departamento.                      |

---


