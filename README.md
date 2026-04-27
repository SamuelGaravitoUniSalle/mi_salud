# MiSalud 🏥

Repositorio de la segunda entrgea del proyecto  de la asignatura **Bases de Datos**. 

MiSalud es el diseño e implementación de la base de datos para una plataforma centralizada del sistema de salud colombiano, que gestiona usuarios, médicos, IPS, EPS, citas, procedimientos, registros clínicos, ect. 

---

## Estructura del repositorio

```
mi_salud/
├── MER/          # Modelo Entidad-Relación (DBML + PNG)
├── DDL/          # Script para crear el esquema y las tablas
├── DML/          # Script para poblar parcialmente la base de datos
└── DCL/          # Script de permisos y control de acceso
```

---

## Pasos realizados

### 1. Modelo Entidad-Relación (MER)
Se diseñó el MER como punto de partida para definir entidades, atributos y relaciones del sistema. En la carpeta `MER/` se encuentra:
- El código **DBML** del modelo.
- El diagrama renderizado en **PNG**.
- El link a **dbdiagram.io** para una vista interactiva.

### 2. Despliegue del servidor en AWS (PostgreSQL)
Se eligió **PostgreSQL** como motor de base de datos y se desplegó un servidor en **Amazon RDS** usando el free tier, en la región **us-east-1 (Norte de Virginia)** — se descartó São Paulo por su mayor costo, aunque tenga menor latencia.

**Configuración del servidor:**
- **Host:** `mi-salud-server.c6touayek8gg.us-east-1.rds.amazonaws.com`
- **Puerto:** `5432`
- **Base de datos:** `mi_salud_db`
- **Regla de entrada:** tráfico permitido en el puerto 5432 desde cualquier IP.

**Credenciales de acceso (solo lectura para quien desee echar un vistazo):**
```
Host:     mi-salud-server.c6touayek8gg.us-east-1.rds.amazonaws.com
Puerto:   5432
Base de datos: mi_salud_db
Usuario:  mi_salud_db_read_only
Password: 1234
```

### 3. Creación del esquema con DDL
Con el servidor activo, se ejecutó el script `DDL/raise_database.sql` para crear el esquema `misalud` con todas sus tablas, atributos, relaciones y restricciones, siguiendo las reglas de normalización hasta la **Tercera Forma Normal (3FN)** y garantizando la integridad de la información.

### 4. Población parcial de la base de datos con DML
Se ejecutó `DML/populate_database_partially.sql` para insertar datos en las **tablas maestras/auxiliares** (catálogos de referencia). Las tablas transaccionales se dejaron pendientes para próximas etapas, dado que sus inserciones requieren múltiples referencias entre tablas.

### 5. Sincronización MER ↔ Base de datos
Se utilizó la librería de Node.js **`db2dbml`** para conectarse a la base de datos desplegada y generar el código DBML directamente desde el esquema real, verificando así que el MER diseñado y la base de datos implementada estuviesen completamente sincronizados.

---

## Nota sobre herramientas utilizadas
- Se utilizó **Claude (IA de Anthropic)** para apoyar el formateo de los datos de inserción y la documentación de los scripts SQL.
- Como complemento se deja en `DCL/mi_salud_db_read_only.sql` las sentencias usadas para crear el usuario de lectura para quien este interesado. 
