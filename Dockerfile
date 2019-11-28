FROM php:7.4-rc-fpm-alpine

LABEL org.label-schema.schema-version="1.0" \
    org.label-schema.vendor="Marc-André Appel <marc-andre@appel.fun>" \
    org.label-schema.name="marcandreappel/tug-php-fpm" \
    org.label-schema.description="A small PHP Docker Image" \
    org.label-schema.url="https://hub.docker.com/r/marcandreappel/tug-php-fpm" \
    org.label-schema.build-date=$DATE \
    org.label-schema.version="$VERSION" \
    org.label-schema.vcs-url="$URL" \
    org.label-schema.vcs-branch="$BRANCH" \
    org.label-schema.vcs-ref="$COMMIT"

WORKDIR /var/www/html

RUN set -eux; \
    \
    # Install some php extensions
    apk add --update --no-cache --virtual .build-deps \
        freetype-dev \
        gmp-dev \
        icu-dev \
        imagemagick-dev \
        libintl \
        libjpeg-turbo-dev \
        libpng-dev \
        libxml2-dev \
        libzip-dev \
        postgresql-dev \
        zlib-dev \
        $PHPIZE_DEPS \
    ; \
    docker-php-ext-configure gd \
        --with-freetype-dir=/usr/include/ \
        --with-png-dir=/usr/include/ \
        --with-jpeg-dir=/usr/include/ \
    ; \
    docker-php-ext-install -j"$(getconf _NPROCESSORS_ONLN)" \
        bcmath gd gmp intl pcache pdo_mysql pcntl sockets zip; \
    pecl update-channels; \
    pecl install imagick redis xdebug; \
    docker-php-ext-enable imagick redis xdebug; \
    rm -rf /tmp/pear ~/.pearrc; \
    runDeps="$( \
        scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
            | tr ',' '\n' \
            | sort -u \
            | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )"; \
    apk add --update --no-cache --virtual .run-deps $runDeps; \
    apk del .build-deps; \
    \
    php --version
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 9000

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
