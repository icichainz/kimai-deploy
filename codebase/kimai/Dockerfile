#  _  ___                 _
# | |/ (_)_ __ ___   __ _(_)
# | ' /| | '_ ` _ \ / _` | |
# | . \| | | | | | | (_| | |
# |_|\_\_|_| |_| |_|\__,_|_|
#
# Kimai image for Apache + PHP - Production Optimized
# ---------------------------------------------------------------------

# Kimai version/tag
ARG KIMAI="main"
# Timezone for images
ARG TIMEZONE="Europe/Berlin"

###########################
# Shared tools
###########################

FROM composer:latest AS composer

###########################
# PHP extensions
###########################

FROM php:8.3-apache-bookworm AS php-ext-base
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libldap2-dev \
        libicu-dev \
        libpng-dev \
        libzip-dev \
        libxslt1-dev \
        libfreetype6-dev && \
    rm -rf /var/lib/apt/lists/*

FROM php-ext-base AS php-ext-gd
RUN docker-php-ext-configure gd --with-freetype && \
    docker-php-ext-install -j$(nproc) gd

FROM php-ext-base AS php-ext-intl
RUN docker-php-ext-install -j$(nproc) intl

FROM php-ext-base AS php-ext-ldap
RUN docker-php-ext-configure ldap && \
    docker-php-ext-install -j$(nproc) ldap

FROM php-ext-base AS php-ext-pdo_mysql
RUN docker-php-ext-install -j$(nproc) pdo_mysql

FROM php-ext-base AS php-ext-zip
RUN docker-php-ext-install -j$(nproc) zip

FROM php-ext-base AS php-ext-xsl
RUN docker-php-ext-install -j$(nproc) xsl

FROM php-ext-base AS php-ext-opcache
RUN docker-php-ext-install -j$(nproc) opcache

###########################
# Runtime base
###########################

FROM php:8.3-apache-bookworm AS runtime-base
ARG TIMEZONE

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bash \
        haveged \
        libicu72 \
        libldap-common \
        libpng16-16 \
        libzip4 \
        libxslt1.1 \
        libfreetype6 \
        unzip \
        curl \
        tzdata && \
    rm -rf /var/lib/apt/lists/* && \
    echo "Listen 8001" > /etc/apache2/ports.conf && \
    a2enmod rewrite && \
    touch /use_apache

COPY .docker/000-default.conf /etc/apache2/sites-available/000-default.conf

# Copy PHP extensions
COPY --from=php-ext-xsl /usr/local/etc/php/conf.d/docker-php-ext-xsl.ini /usr/local/etc/php/conf.d/
COPY --from=php-ext-xsl /usr/local/lib/php/extensions/no-debug-non-zts-20230831/xsl.so /usr/local/lib/php/extensions/no-debug-non-zts-20230831/
COPY --from=php-ext-pdo_mysql /usr/local/etc/php/conf.d/docker-php-ext-pdo_mysql.ini /usr/local/etc/php/conf.d/
COPY --from=php-ext-pdo_mysql /usr/local/lib/php/extensions/no-debug-non-zts-20230831/pdo_mysql.so /usr/local/lib/php/extensions/no-debug-non-zts-20230831/
COPY --from=php-ext-zip /usr/local/etc/php/conf.d/docker-php-ext-zip.ini /usr/local/etc/php/conf.d/
COPY --from=php-ext-zip /usr/local/lib/php/extensions/no-debug-non-zts-20230831/zip.so /usr/local/lib/php/extensions/no-debug-non-zts-20230831/
COPY --from=php-ext-ldap /usr/local/etc/php/conf.d/docker-php-ext-ldap.ini /usr/local/etc/php/conf.d/
COPY --from=php-ext-ldap /usr/local/lib/php/extensions/no-debug-non-zts-20230831/ldap.so /usr/local/lib/php/extensions/no-debug-non-zts-20230831/
COPY --from=php-ext-gd /usr/local/etc/php/conf.d/docker-php-ext-gd.ini /usr/local/etc/php/conf.d/
COPY --from=php-ext-gd /usr/local/lib/php/extensions/no-debug-non-zts-20230831/gd.so /usr/local/lib/php/extensions/no-debug-non-zts-20230831/
COPY --from=php-ext-intl /usr/local/etc/php/conf.d/docker-php-ext-intl.ini /usr/local/etc/php/conf.d/
COPY --from=php-ext-intl /usr/local/lib/php/extensions/no-debug-non-zts-20230831/intl.so /usr/local/lib/php/extensions/no-debug-non-zts-20230831/
COPY --from=php-ext-opcache /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini /usr/local/etc/php/conf.d/

ENV TIMEZONE=${TIMEZONE}
RUN ln -snf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
    echo ${TIMEZONE} > /etc/timezone

EXPOSE 8001

HEALTHCHECK --interval=20s --timeout=10s --retries=3 \
    CMD curl -f http://127.0.0.1:8001 || exit 1

###########################
# Build stage - Install dependencies
###########################

FROM runtime-base AS builder
ARG KIMAI
ARG TIMEZONE

# Copy composer
COPY --from=composer /usr/bin/composer /usr/bin/composer

# Create composer cache directory
RUN mkdir -p /composer && \
    chown -R www-data:www-data /composer

ENV COMPOSER_HOME=/composer
ENV COMPOSER_MEMORY_LIMIT=-1
ENV COMPOSER_ALLOW_SUPERUSER=1

# Copy only dependency files first (better layer caching)
COPY --chown=www-data:www-data composer.json composer.lock symfony.lock /opt/kimai/

# Install dependencies
WORKDIR /opt/kimai
RUN mkdir -p var/packages && \
    composer install --no-dev --optimize-autoloader --no-scripts --no-autoloader && \
    composer require --update-no-dev --no-scripts laminas/laminas-ldap && \
    composer clearcache

# Now copy the rest of the application
COPY --chown=www-data:www-data . /opt/kimai/

# Generate optimized autoloader
RUN composer dump-autoload --optimize --no-dev --classmap-authoritative

###########################
# Production image
###########################

FROM runtime-base AS prod
ARG KIMAI
ARG TIMEZONE

LABEL org.opencontainers.image.title="Kimai" \
      org.opencontainers.image.description="Kimai is a time-tracking application." \
      org.opencontainers.image.authors="Kimai Community" \
      org.opencontainers.image.url="https://www.kimai.org/" \
      org.opencontainers.image.documentation="https://www.kimai.org/documentation/" \
      org.opencontainers.image.source="https://github.com/kimai/kimai" \
      org.opencontainers.image.version="${KIMAI}" \
      org.opencontainers.image.vendor="Kevin Papst" \
      org.opencontainers.image.licenses="AGPL-3.0"

# Copy application from builder
COPY --from=builder --chown=www-data:www-data /opt/kimai /opt/kimai

# Copy Docker support files
COPY --chown=www-data:www-data .docker/dbtest.php /dbtest.php
COPY --chown=www-data:www-data .docker/entrypoint.sh /entrypoint.sh
COPY --chown=www-data:www-data .docker /assets

# Configure PHP for production
RUN cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini && \
    sed -i "s/expose_php = On/expose_php = Off/g" /usr/local/etc/php/php.ini && \
    sed -i "s/;opcache.enable=1/opcache.enable=1/g" /usr/local/etc/php/php.ini && \
    sed -i "s/;opcache.memory_consumption=128/opcache.memory_consumption=256/g" /usr/local/etc/php/php.ini && \
    sed -i "s/;opcache.interned_strings_buffer=8/opcache.interned_strings_buffer=24/g" /usr/local/etc/php/php.ini && \
    sed -i "s/;opcache.max_accelerated_files=10000/opcache.max_accelerated_files=100000/g" /usr/local/etc/php/php.ini && \
    sed -i "s/opcache.validate_timestamps=1/opcache.validate_timestamps=0/g" /usr/local/etc/php/php.ini && \
    sed -i "s/session.gc_maxlifetime = 1440/session.gc_maxlifetime = 604800/g" /usr/local/etc/php/php.ini && \
    sed "s/128M/-1/g" /usr/local/etc/php/php.ini-development > /opt/kimai/php-cli.ini && \
    sed -i "s/env php/env -S php -c \/opt\/kimai\/php-cli.ini/g" /opt/kimai/bin/console && \
    mkdir -p /opt/kimai/var/logs && \
    chmod 777 /opt/kimai/var/logs && \
    chown -R www-data:www-data /opt/kimai /usr/local/etc/php/php.ini && \
    /opt/kimai/bin/console kimai:version | awk '{print $2}' > /opt/kimai/version.txt 2>/dev/null || echo "${KIMAI}" > /opt/kimai/version.txt

# Environment variables
ENV KIMAI=${KIMAI}
ENV TIMEZONE=${TIMEZONE}
ENV APP_ENV=prod
ENV DATABASE_URL="mysql://kimai:kimai@127.0.0.1:3306/kimai?charset=utf8mb4&serverVersion=8.3"
ENV APP_SECRET=change_this_to_something_unique
ENV TRUSTED_PROXIES=nginx,localhost,127.0.0.1
ENV MAILER_FROM=kimai@example.com
ENV MAILER_URL=null://localhost
ENV ADMINPASS=
ENV ADMINMAIL=
ENV USER_ID=
ENV GROUP_ID=
ENV memory_limit=512M

VOLUME [ "/opt/kimai/var" ]

WORKDIR /opt/kimai

CMD [ "/entrypoint.sh" ]

###########################
# Development image
###########################

FROM runtime-base AS dev
ARG KIMAI
ARG TIMEZONE

# Copy composer
COPY --from=composer /usr/bin/composer /usr/bin/composer

# Create composer cache directory
RUN mkdir -p /composer && \
    chown -R www-data:www-data /composer

ENV COMPOSER_HOME=/composer
ENV COMPOSER_MEMORY_LIMIT=-1
ENV COMPOSER_ALLOW_SUPERUSER=1

# Copy application
COPY --chown=www-data:www-data . /opt/kimai/
COPY --chown=www-data:www-data .docker /assets
COPY --chown=www-data:www-data .docker/dbtest.php /dbtest.php
COPY --chown=www-data:www-data .docker/entrypoint.sh /entrypoint.sh

WORKDIR /opt/kimai

# Install all dependencies (including dev)
RUN mkdir -p var/packages && \
    composer install --optimize-autoloader && \
    composer require --no-scripts laminas/laminas-ldap && \
    composer clearcache && \
    cp /usr/local/etc/php/php.ini-development /usr/local/etc/php/php.ini && \
    mkdir -p /opt/kimai/var/logs && \
    chmod 777 /opt/kimai/var/logs && \
    sed "s/128M/-1/g" /usr/local/etc/php/php.ini-development > /opt/kimai/php-cli.ini && \
    sed -i "s/env php/env -S php -c \/opt\/kimai\/php-cli.ini/g" /opt/kimai/bin/console && \
    chown -R www-data:www-data /opt/kimai /usr/local/etc/php/php.ini && \
    /opt/kimai/bin/console kimai:version | awk '{print $2}' > /opt/kimai/version.txt 2>/dev/null || echo "${KIMAI}-dev" > /opt/kimai/version.txt

ENV KIMAI=${KIMAI}
ENV TIMEZONE=${TIMEZONE}
ENV APP_ENV=dev
ENV DATABASE_URL=
ENV memory_limit=512M
ENV ADMINPASS=
ENV ADMINMAIL=
ENV USER_ID=
ENV GROUP_ID=

VOLUME [ "/opt/kimai/var" ]

CMD [ "/entrypoint.sh" ]
