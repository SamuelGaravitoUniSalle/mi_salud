FROM postgres:latest

COPY DDL/raise_database.sql  /tmp/raise_database.sql
COPY DML/populate_database.sql /tmp/populate_database.sql
COPY docker-init.sh          /docker-entrypoint-initdb.d/init.sh

RUN chmod +x /docker-entrypoint-initdb.d/init.sh
