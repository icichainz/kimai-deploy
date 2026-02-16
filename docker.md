version: '3.8'

services:
  kimai:
    image: kimai/kimai2:apache
    container_name: kimai
    restart: unless-stopped
    environment:
      - DATABASE_URL=postgresql://kimai:kimai_password@db:5432/kimai?charset=utf8&serverVersion=15
      - APP_SECRET=change_this_to_something_unique_and_secret
      - TRUSTED_HOSTS=localhost,127.0.0.1,kimai.yourdomain.com
      - TRUSTED_PROXIES=caddy
      - ADMINMAIL=admin@example.com
      - ADMINPASS=admin_password_change_me
    volumes:
      - kimai_data:/opt/kimai/var
    depends_on:
      - db
    networks:
      - caddy
    labels:
      caddy: kimai.yourdomain.com
      caddy.reverse_proxy: "{{upstreams 8001}}"

  db:
    image: postgres:15-alpine
    container_name: kimai_db
    restart: unless-stopped
    environment:
      - POSTGRES_DB=kimai
      - POSTGRES_USER=kimai
      - POSTGRES_PASSWORD=kimai_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - caddy

volumes:
  kimai_data:
  postgres_data:

networks:
  caddy:
    external: true