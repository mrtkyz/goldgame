FROM caddy:2-alpine

COPY Caddyfile /etc/caddy/Caddyfile
COPY index.html goldgame.html yilan.html bisiklet.html /srv/

EXPOSE 80 443

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wget -q --spider http://localhost/ || exit 1
