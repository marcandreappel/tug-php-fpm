ARG BRANCH
ARG COMMIT
ARG DATE
ARG URL
ARG VERSION

FROM php:7.4.0-fpm-alpine

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

ENV PHP_ENABLE_XDEBUG=1 \
    PHP_MEMORY_LIMIT=128M \
    PHP_MAX_EXEC_TIME=3600 \
    PHP_MAX_FILE_UPLOADS=20 \
    PHP_POST_MAX_SIZE=256M \
    PHP_UPLOAD_MAX_SIZE=256M \
    PHP_TIMEZONE=UTC

RUN set -eux; apk add --update --no-cache --virtual .build-deps \
        freetype-dev \
        gmp-dev \
        icu-dev \
        libintl \
        libjpeg-turbo-dev \
        libpng-dev \
        libxml2-dev \
        libzip-dev \
        oniguruma-dev \
        openssl-dev \
        zlib-dev \
        $PHPIZE_DEPS; \
    docker-php-ext-configure gd \
            --with-freetype-dir=/usr/include/ \
            --with-png-dir=/usr/include/ \
            --with-jpeg-dir=/usr/include/ ; \
	docker-php-ext-install -j"$(getconf _NPROCESSORS_ONLN)" \
		bcmath gd gmp intl mbstring opcache phar mysqli pdo pdo_mysql pcntl sockets zip; \
	pecl update-channels; \
	pecl install apcu redis xdebug; \
	docker-php-ext-enable apcu redis xdebug; \
	rm -rf /tmp/pear ~/.pearrc; \
	runDeps="$(scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
                | tr ',' '\n' \
                | sort -u \
                | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }')"; \
        apk add --update --no-cache --virtual .run-deps supervisor $runDeps; \
        apk del .build-deps;

COPY supervisord.conf /etc/supervisord/conf.d/supervisord.conf

COPY xdebug.ini /etc/php7/conf.d/xdebug.ini

EXPOSE 9000

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord/conf.d/supervisord.conf"]
