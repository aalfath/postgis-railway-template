# Changelog

## Unreleased (2026-11-16)

- README: Deploy on Railway button for the published template `postgis-1`. No change to the database image or start scripts.

## 18-3.7.0 (2026-11-16)

First release.

- PostGIS 3.7.0 on PostgreSQL 18 (Debian trixie): `postgis/postgis:18-3.7@sha256:e55337da273845fb2ad38f6151953f70fd93ac8ac2a3d2edbc4056c858783a5f` (built 2026-11-14).
- Data on a volume at `/var/lib/postgresql` (`PGDATA=/var/lib/postgresql/18/docker`).
- On first start: `postgis`, `postgis_topology` and `postgis_raster` are created in the default database and in `template_postgis`.
- Memory defaults set once with `ALTER SYSTEM` on first start: `shared_buffers=512MB`, `effective_cache_size=1536MB`, `maintenance_work_mem=256MB`, `work_mem=16MB`.
- Dynamic shared memory in the data directory (`dynamic_shared_memory_type=mmap`), so parallel queries don't fail on a small `/dev/shm`.
- Self-signed TLS certificate generated on first start and renewed before expiry.
- SIGTERM from Railway becomes a fast Postgres shutdown.
