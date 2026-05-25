#!/bin/bash
set -e

psql --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" \
    -f /tmp/raise_database.sql
psql --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" \
    -f /tmp/populate_database.sql
