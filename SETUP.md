# Setup local - MiSalud con Docker

Levanta la base de datos PostgreSQL en local sin necesidad de tener Postgres instalado.

## Requisitos

- [Docker](https://docs.docker.com/get-docker/) instalado y corriendo.

---

## Levantar la base de datos

### 1. Construir la imagen

Desde la raíz del repositorio:

```bash
docker build -t misalud-db .
```

### 2. Correr el contenedor

```bash
docker run -d \
  -p 5433:5432 \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=1234 \
  -e POSTGRES_DB=mi_salud \
  --name misalud-db \
  misalud-db
```

> Se usa el puerto **5433** en el host para evitar conflicto con una instalación local de Postgres que ocupe el 5432.

Al primer arranque el contenedor ejecuta automáticamente:
1. `DDL/raise_database.sql` - crea el esquema `misalud` con todas las tablas.
2. `DML/populate_database.sql` - inserta los datos de catálogos y dominio.

---

## Conectarse a la base de datos


**Connection string:**
```
postgresql://postgres:1234@localhost:5433/mi_salud
```

#### Desde la terminal con psql

```bash
psql -h localhost -p 5433 -U postgres -d mi_salud
```

#### Desde dentro del contenedor

```bash
docker exec -it misalud-db psql -U postgres -d mi_salud
```



