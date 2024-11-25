FROM php:8.4-cli-alpine

RUN set -xe \
    && : "---------- Fix possible vulnerabilities ----------" \
    && apk --update --no-cache upgrade \
    && : "---------- Persistent dependencies ----------" \
    && apk add --no-cache --virtual .persistent-dependencies \
        ssmtp \
        bash \
    && : "---------- Build dependencies ----------" \
    && apk add --no-cache --virtual .build-dependencies \
		autoconf \
		dpkg-dev dpkg \
		file \
		g++ \
		gcc \
        git \
		libc-dev \
		make \
		pkgconf \
		re2c \
        freetype-dev \
        libjpeg-turbo-dev \
        libpng-dev \
        libwebp-dev \
        libxslt-dev \
        zlib-dev \
        icu-dev \
    && : "---------- extract php source ----------" \
    && docker-php-source extract \
    && : "---------- php extensions ----------" \
    && docker-php-ext-configure gd \
        --prefix=/usr \
        --with-freetype \
        --with-jpeg \
        --with-webp \
    && docker-php-ext-configure intl \
    && docker-php-ext-install -j$(nproc) bcmath exif gd intl opcache pcntl mysqli pdo_mysql xsl \
    && : "---------- redis ----------" \
    && pecl install -o -f redis \
    && docker-php-ext-enable redis \
    # && : "---------- xdebug ----------" \
    # && pecl install -o -f xdebug \
    # && docker-php-ext-enable xdebug \
    && : "---------- runtime dependencies ----------" \
    && runtimeDeps="$( \
        scanelf --needed --nobanner --recursive /usr/local \
        | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
        | sort -u \
        | xargs -r apk info --installed \
        | sort -u \
    )" \
    && apk add --virtual .runtime-dependencies ${runtimeDeps} \
    && : "---------- Clean up ----------" \
    && docker-php-source delete \
    && apk del .build-dependencies \
    && rm -rf \
        /tmp/* \
        /usr/includes/* \
        /usr/share/man/* \
        /usr/src/* \
        /var/cache/apk/* \
        /var/tmp/* \
    && : "---------- Copy config ----------" \
    && mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" \
    && : "---------- Create /app ----------" \
    && mkdir /app

COPY conf.d $PHP_INI_DIR/conf.d/
COPY ssmtp/ssmtp.conf /etc/ssmtp/ssmtp.conf

RUN set -xe \
    && : "---------- Display some debug output ----------" \
    && php --version && php --ini && php -m

WORKDIR /app
