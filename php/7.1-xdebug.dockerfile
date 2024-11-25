FROM php:7.4-fpm-alpine

ARG REDIS_TAG=4.3.0
ARG XDEBUG_BRANCH=master

RUN set -xe \
    && : "---------- Persistent dependencies ----------" \
    && apk add --no-cache --virtual .persistent-dependencies \
        curl \
        git \
        ssmtp \
        tini \
    && : "---------- Build dependencies ----------" \
    && apk add --virtual .build-dependencies \
        autoconf \
        bison \
        bzip2-dev \
        dpkg-dev \
        file \
        freetype-dev \
        g++ \
        gcc \
        git \
        icu-dev \
        libevent-dev \
        libjpeg-turbo-dev \
        libmagic\
        libpng-dev \
        libtool \
        libwebp-dev \
        libxml2-dev \
        libzip-dev \
        make \
        pcre-dev \
        re2c \
        zlib-dev \
    && : "---------- Build flags ----------" \
    && export CFLAGS="-O2 -march=native -fstack-protector-strong -fpic -fpie" \
    && export CPPFLAGS=${CFLAGS} \
    && export LDFLAGS="-Wl,-O2 -Wl,--hash-style=both -pie" \
    && export MAKEFLAGS="-j $(expr $(getconf _NPROCESSORS_ONLN) \+ 1)" \
    && : "---------- Configure PHP extensions ----------" \
    && docker-php-ext-configure gd \
        --with-gd \
        --with-freetype-dir=/usr \
        --with-jpeg-dir=/usr \
        --with-png-dir=/usr \
        --with-webp-dir=/usr \
        --with-xpm-dir=no \
        --with-zlib-dir=/usr \
    && docker-php-ext-configure bcmath --enable-bcmath \
    && docker-php-ext-configure exif --enable-exif \
    && docker-php-ext-configure intl --enable-intl \
    && docker-php-ext-configure pcntl --enable-pcntl \
    && docker-php-ext-configure mysqli --with-mysqli \
    && docker-php-ext-configure pdo_mysql --with-pdo-mysql \
    && docker-php-ext-configure mbstring --enable-mbstring \
    && : "---------- Install PHP extensions ----------" \
    && docker-php-ext-install \
        bcmath \
        exif \
        gd \
        intl \
        mbstring \
        mysqli \
        pcntl \
        pdo_mysql \
    && : "---------- Redis ----------" \
    && git clone --branch ${REDIS_TAG} --depth 1 https://github.com/phpredis/phpredis.git /tmp/redis \
    && cd /tmp/redis \
    && phpize \
    && ./configure \
    && make \
    && make install \
    && : "---------- xDebug ----------" \
    && git clone --branch ${XDEBUG_BRANCH} --depth 1 https://github.com/xdebug/xdebug.git /tmp/xdebug \
    && cd /tmp/xdebug \
    && phpize \
    && ./configure \
    && make \
    && make install \
    && : "---------- Runtime dependencies ----------" \
    && runtimeDeps="$( \
        scanelf --needed --nobanner --recursive /usr/local \
        | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
        | sort -u \
        | xargs -r apk info --installed \
        | sort -u \
    )" \
    && apk add --virtual .runtime-dependencies ${runtimeDeps} \
    && : "---------- Clean up ----------" \
    && apk del .build-dependencies \
    && rm -rf \
        /tmp/* \
        /usr/includes/* \
        /usr/share/man/* \
        /usr/src/* \
        /var/cache/apk/* \
        /var/tmp/* \
    && : "---------- Create /app ----------" \
    && mkdir /app

COPY etc /usr/local/etc

RUN set -xe \
  && : "---------- Install composer ----------" \
  && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
  && composer config --global repo.packagist composer https://packagist.org \
  && : "---------- Debug info ----------" \
  && php --version && php --ini && php -m

WORKDIR /app

RUN set -xe \
    && : "---------- Display some debug output ----------" \
    && php --version && php --ini && php -m

ENTRYPOINT ["tini", "--"]
CMD ["php-fpm"]
