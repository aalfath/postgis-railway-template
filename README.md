# PostGIS on Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/postgis-1?utm_medium=integration&utm_source=button&utm_campaign=postgis)

Railway template for [PostGIS](https://postgis.net/), the spatial database extension for PostgreSQL, running PostGIS 3.7 on PostgreSQL 18.

This repo is what the template builds: a `Dockerfile` that pins the official image `postgis/postgis:18-3.7` by digest, a first-start script (`initdb/20-railway.sh`) and a small start script (`railway-entrypoint.sh`).

## What you get

- **PostGIS 3.7.0 on PostgreSQL 18** (official `postgis/postgis` image, Debian trixie).
- **Extensions ready on first boot:** `postgis`, `postgis_topology` and `postgis_raster` are created in the default database and in `template_postgis`. Create more spatial databases with `CREATE DATABASE gis TEMPLATE template_postgis;`. PostGIS 3.7 no longer ships the US Tiger geocoder.
- **Persistent data** on a Railway volume mounted at `/var/lib/postgresql` (`PGDATA=/var/lib/postgresql/18/docker`).
- **Generated password:** `POSTGRES_PASSWORD` is a random 32-character secret. There is no default password.
- **TLS:** a self-signed certificate is generated on first start, kept on the volume and renewed 30 days before it expires. Clients using `sslmode=prefer` or `require` get an encrypted connection.
- **Sensible memory settings:** `shared_buffers=512MB`, `effective_cache_size=1536MB`, `maintenance_work_mem=256MB` and `work_mem=16MB` are set on first start with `ALTER SYSTEM`, so you can change them later. Dynamic shared memory lives in the data directory, so parallel queries don't fail with "could not resize shared memory segment" on the container's small `/dev/shm`.
- **Private and public access:** other services connect over Railway's private network with `${{PostGIS.DATABASE_URL}}`. A TCP proxy on port 5432 gives `DATABASE_PUBLIC_URL` for tools outside Railway (psql, QGIS, DBeaver, ogr2ogr).
- **Clean redeploys:** the start script turns Railway's SIGTERM into a fast shutdown, so Postgres checkpoints and stops within the 60 s draining window.

## Variables

| Variable | Default | Notes |
|---|---|---|
| `POSTGRES_USER` | `postgres` | Superuser name |
| `POSTGRES_PASSWORD` | `${{secret(32)}}` | Generated at deploy time |
| `POSTGRES_DB` | `railway` | Default database, created with PostGIS |
| `PGHOST`, `PGPORT`, `PGUSER`, `PGPASSWORD`, `PGDATABASE` | references | libpq-style connection settings for other services |
| `DATABASE_URL` | private URL | `postgresql://…@${{RAILWAY_PRIVATE_DOMAIN}}:5432/…` |
| `DATABASE_PUBLIC_URL` | public URL | Through the TCP proxy |
| `RAILWAY_DEPLOYMENT_DRAINING_SECONDS` | `60` | Time Postgres gets to shut down on redeploy |

Optional, not in the template (add them to the service if you need them):

- `PG_SHARED_BUFFERS` (default `512MB`), `PG_EFFECTIVE_CACHE_SIZE` (`1536MB`), `PG_MAINTENANCE_WORK_MEM` (`256MB`), `PG_WORK_MEM` (`16MB`): used only when the database is first created. To change them later, run `ALTER SYSTEM SET work_mem = '64MB';` and redeploy.
- `PG_DYNAMIC_SHARED_MEMORY_TYPE` (default `mmap`): set to `posix` to use `/dev/shm` instead.
- `SSL_CERT_DAYS` (default `820`): lifetime of the generated certificate.

## Connect

From another Railway service: set `DATABASE_URL=${{PostGIS.DATABASE_URL}}`.

From your machine: copy `DATABASE_PUBLIC_URL` from the service's Variables tab, then

```sh
psql "$DATABASE_PUBLIC_URL"
```

```sql
SELECT postgis_full_version();
CREATE TABLE places (id bigserial PRIMARY KEY, name text, geom geometry(Point, 4326));
CREATE INDEX ON places USING gist (geom);
INSERT INTO places (name, geom) VALUES ('Jakarta', ST_SetSRID(ST_MakePoint(106.8456, -6.2088), 4326));
SELECT name FROM places WHERE ST_DWithin(geom::geography, ST_MakePoint(106.8, -6.2)::geography, 10000);
```

Load a shapefile or GeoJSON with GDAL: `ogr2ogr -f PostgreSQL PG:"$DATABASE_PUBLIC_URL" data.geojson`.

## Updates

Deployers get Railway's "update available" notice when this repo's `main` branch changes. Each change is listed in [CHANGELOG.md](CHANGELOG.md); read it before you apply an update.

- **PostGIS minor updates** (3.7.0 → 3.7.1) swap the image. After the redeploy, run `SELECT postgis_extensions_upgrade();` in each database that uses PostGIS (including `template_postgis`) to bring `postgis`, `postgis_topology` and `postgis_raster` to the new version.
- **PostgreSQL minor updates** (18.x → 18.y) only need the redeploy.
- **PostgreSQL major upgrades** (18 → 19) are never applied automatically: they need `pg_upgrade` or a dump and restore, and the changelog will say so first.

## License

The wrapper in this repo is MIT. PostGIS is under the [GPL-2.0](https://github.com/postgis/postgis/blob/master/COPYING); the Docker image recipe ([postgis/docker-postgis](https://github.com/postgis/docker-postgis)) is MIT.
