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

RUN apk update && apk add composer git sqlite3 supervisor unzip zsh \
	&& sed -i "s/pm\.max_children = .*/pm.max_children = 20/" /etc/php/7.4/fpm/pool.d/www.conf \
    && sed -i "s/pm\.start_servers = .*/pm.start_servers = 10/" /etc/php/7.4/fpm/pool.d/www.conf \
    && sed -i "s/pm\.min_spare_servers = .*/pm.min_spare_servers = 5/" /etc/php/7.4/fpm/pool.d/www.conf \
    && sed -i "s/pm\.max_spare_servers = .*/pm.max_spare_servers = 10/" /etc/php/7.4/fpm/pool.d/www.conf \
	&& mkdir /run/php \
	&& docker-php-ext-install bcmath exif igbinary mbstring pdo_mysql readline redis xdebug zip \
	&& docker-php-ext-configure gd --with-gd --with-freetype-dir=/usr/include/ \
		--with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include/ \
	&& docker-php-ext-install gd

COPY php-fpm.conf /etc/php/7.4/fpm/php-fpm.conf
COPY xdebug.ini /etc/php/7.4/mods-available/xdebug.ini
COPY tug.ini /etc/php/7.4/fpm/conf.d/99-tug.ini
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 9000

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
