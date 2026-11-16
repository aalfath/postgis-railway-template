# PostGIS 3.7.0 on PostgreSQL 18 (Debian trixie), official image pinned by digest.
FROM postgis/postgis:18-3.7@sha256:e55337da273845fb2ad38f6151953f70fd93ac8ac2a3d2edbc4056c858783a5f

# PostgreSQL 18 data layout. Mount the Railway volume at /var/lib/postgresql.
ENV PGDATA=/var/lib/postgresql/18/docker

# First-start setup. The image's own 10_postgis.sh creates template_postgis plus
# the postgis and postgis_topology extensions; 20-railway.sh adds postgis_raster
# and memory defaults. Only our script is made executable: the image sources
# 10_postgis.sh (it needs the entrypoint's psql array), and executes 20-railway.sh.
COPY initdb/ /docker-entrypoint-initdb.d/
COPY railway-entrypoint.sh /usr/local/bin/railway-entrypoint.sh
RUN chmod 0755 /usr/local/bin/railway-entrypoint.sh /docker-entrypoint-initdb.d/20-railway.sh

EXPOSE 5432
ENTRYPOINT ["/usr/local/bin/railway-entrypoint.sh"]
CMD []
