FROM php:7.4-fpm-alpine

# Setup GD extension
RUN apk add --no-cache \
      freetype \
      libjpeg-turbo \
      libpng \
      freetype-dev \
      libjpeg-turbo-dev \
      libpng-dev \
    && docker-php-ext-configure gd \
      --with-freetype=/usr/include/ \
      # --with-png=/usr/include/ \ # No longer necessary as of 7.4; https://github.com/docker-library/php/pull/910#issuecomment-559383597
      --with-jpeg=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-enable gd \
    && apk del --no-cache \
      freetype-dev \
      libjpeg-turbo-dev \
      libpng-dev \
    && rm -rf /tmp/*

RUN apk add nginx libzip-dev

RUN docker-php-ext-install pdo pdo_mysql zip bcmath pcntl

RUN cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini

RUN mkdir -p /var/log/php

RUN chown -R www-data:www-data /var/log/php

COPY php/php-fpm.conf /usr/local/etc/php-fpm.conf

COPY php/php-fpm.d /usr/local/etc/php-fpm.d

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

WORKDIR /var/www

COPY /api /var/www

RUN composer install --optimize-autoloader --no-dev

RUN chown -R www-data:www-data /var/www /var/www/bootstrap/cache

COPY nginx/default.conf /etc/nginx/http.d/default.conf

ENTRYPOINT nginx && php-fpm
