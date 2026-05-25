
CREATE USER mi_salud_db_read_only WITH PASSWORD '1234';
GRANT CONNECT ON DATABASE mi_salud to mi_salud_db_read_only; 
GRANT USAGE ON SCHEMA misalud TO mi_salud_db_read_only;
GRANT SELECT ON ALL TABLES IN SCHEMA misalud TO mi_salud_db_read_only;
ALTER DEFAULT PRIVILEGES IN SCHEMA misalud 
GRANT SELECT ON TABLES TO mi_salud_db_read_only;