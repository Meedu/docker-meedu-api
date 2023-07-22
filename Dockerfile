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

# nginx配置文件
COPY nginx/default.conf /etc/nginx/http.d/default.conf

RUN docker-php-ext-install pdo pdo_mysql zip bcmath pcntl opcache

# PHP配置文件
COPY php/php.ini /usr/local/etc/php/php.ini

RUN mkdir -p /var/log/php

RUN chown -R www-data:www-data /var/log/php

COPY php/php-fpm.conf /usr/local/etc/php-fpm.conf

COPY php/php-fpm.d /usr/local/etc/php-fpm.d

# 安装composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# 设置工作目录
WORKDIR /var/www

# 复制源代码到容器
COPY /api /var/www

# 安装依赖
RUN composer install --optimize-autoloader --no-dev

# 目录权限
RUN chown -R www-data:www-data /var/www /var/www/bootstrap/cache

# laravel框架的一些操作
RUN php artisan route:cache && php artisan storage:link && php artisan install:lock

ENTRYPOINT nginx && php-fpm
