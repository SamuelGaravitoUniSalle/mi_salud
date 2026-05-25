# MiSalud 🏥

Repositorio del proyecto  de la asignatura **Bases de Datos**. 

MiSalud es el diseño e implementación de la base de datos para una plataforma centralizada del sistema de salud colombiano, que gestiona usuarios, médicos, IPS, EPS, citas, procedimientos, registros clínicos, ect. 

---

## Estructura del repositorio

```
mi_salud/
├── MER/              # Modelo Entidad-Relación (DBML + PNG)
├── DDL/              # Scripts para la creación del esquema y las tablas
├── DML/              # Scripts SQL para poblar la base de datos con datos reales
├── DCL/              # Scripts de permisos y control de acceso
├── Dockerfile        # Imagen Docker con PostgreSQL + scripts precargados
├── docker-init.sh    # Entrypoint que ejecuta DDL y DML al arrancar
└── SETUP.md          # Guía para levantar la base de datos en local con Docker
```

---

## Pasos realizados

### 1. Modelo Entidad-Relación (MER)
Se diseñó el MER como punto de partida para definir entidades, atributos y relaciones del sistema. En la carpeta `MER/` se encuentra:
- El código **DBML** del modelo.
- El diagrama renderizado en **PNG**.
- El link a **dbdiagram.io** para una vista interactiva.

### 2. Despliegue del servidor en AWS (PostgreSQL)
Se eligió **PostgreSQL** como motor de base de datos y se desplegó un servidor usando el free tier, en la región **us-east-1 (Norte de Virginia)** — se descartó São Paulo por su mayor costo, aunque tenga menor latencia.

**Configuración del servidor: **
- **Host:** `dpg-d89mpdrbc2fs73fd0hn0-a.virginia-postgres.render.com`
- **Puerto:** `5432`
- **Base de datos:** `mi_salud`
- **Regla de entrada:** tráfico permitido en el puerto 5432 desde cualquier IP.

*La infraestructura del servidor cambió. Aunque la capa base continúa siendo AWS, ahora se incorporó un intermediario mediante Render. Esta decisión se tomó debido a que, en la entrega anterior, se superó el límite del free tier de AWS, lo que generó costos adicionales.*

**Credenciales de acceso (solo lectura para quien desee echar un vistazo):**
```
Host:     dpg-d89mpdrbc2fs73fd0hn0-a.virginia-postgres.render.com
Puerto:   5432
Base de datos: mi_salud_db
Usuario:  mi_salud_db_read_only
Password: 1234
```

### 3. Creación del esquema con DDL
Con el servidor activo, se ejecutó el script `DDL/raise_database.sql` para crear el esquema `misalud` con todas sus tablas, atributos, relaciones y restricciones, siguiendo las reglas de normalización hasta la **Tercera Forma Normal (3FN)** y garantizando la integridad de la información.

### 4. Población de la base de datos con DML
Se ejecutó `DML/populate_database.sql` para insertar datos en las tablas.

### 5. Consultas SQL — Indicadores de negocio
Se desarrollaron 10 consultas analíticas almacenadas en `DML/query_0N.sql`. Cada una responde a un objetivo funcional concreto:

| Archivo | Tipo | Propósito principal |
|---|---|---|
| `query_01.sql` | Reporte | Ranking de EPS por afiliados y volumen de citas |
| `query_02.sql` | Gestión clínica | Adultos mayores sin atención registrada en MiSalud |
| `query_03.sql` | Cobertura | Cobertura territorial de IPS por departamento |
| `query_04.sql` | Programación | Matriz IPS × día de la semana con disponibilidad y saturación |
| `query_05.sql` | Talento humano | Distribución de médicos por especialidad |
| `query_06.sql` | Transformación | Segmentación de afiliados por adopción de telemedicina |
| `query_07.sql` | Calidad | Especialidades con citas pero sin autorizaciones |
| `query_08.sql` | Auditoría | Citas atendidas sin HCE — incumplimiento Res. 1995/1999 y Res. 839/2017 |
| `query_09.sql` | Inversión | IPS de alta capacidad habilitadas en las TOP-3 especialidades más demandadas |
| `query_10.sql` | Gerencia | `VIEW v_dashboard_gerencial` — tablero KPI por departamento |

### 6. Sincronización MER ↔ Base de datos
Se utilizó la librería de Node.js **`db2dbml`** para conectarse a la base de datos desplegada y generar el código DBML directamente desde el esquema real, verificando así que el MER diseñado y la base de datos implementada estuviesen completamente sincronizados.

### 7. Setup local con Docker
Para facilitar la reproducibilidad, se añade soporte para levantar la base de datos en local sin tener PostgreSQL instalado. El `Dockerfile` construye una imagen que al arrancar ejecuta automáticamente el DDL y el DML mediante `docker-init.sh`. Consulta **`SETUP.md`** para los pasos detallados.

---

## Nota sobre herramientas utilizadas
- Se utilizó **Claude (IA de Anthropic)** para apoyar el formateo de los datos de inserción y la documentación de los scripts SQL.
- Como complemento se deja en `DCL/mi_salud_db_read_only.sql` las sentencias usadas para crear el usuario de lectura para quien este interesado. 
