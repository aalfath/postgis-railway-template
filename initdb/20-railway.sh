#!/bin/bash
# Runs once, when the database is first created (docker-entrypoint-initdb.d),
# after the image's 10_postgis.sh (template_postgis, postgis, postgis_topology).
# - adds postgis_raster to the default database and to template_postgis
# - stores memory settings with ALTER SYSTEM (postgresql.auto.conf), so they
#   can be changed later with ALTER SYSTEM and a restart
set -euo pipefail

for db in "$POSTGRES_DB" template_postgis; do
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$db" -c 'CREATE EXTENSION IF NOT EXISTS postgis_raster;'
done

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<SQL
ALTER SYSTEM SET shared_buffers = '${PG_SHARED_BUFFERS:-512MB}';
ALTER SYSTEM SET effective_cache_size = '${PG_EFFECTIVE_CACHE_SIZE:-1536MB}';
ALTER SYSTEM SET maintenance_work_mem = '${PG_MAINTENANCE_WORK_MEM:-256MB}';
ALTER SYSTEM SET work_mem = '${PG_WORK_MEM:-16MB}';
SQL
echo "postgis: postgis, postgis_topology and postgis_raster ready in ${POSTGRES_DB} and template_postgis"
