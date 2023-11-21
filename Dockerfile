FROM php:7.4-fpm-alpine

RUN apk update && apk upgrade && apk add --no-cache \
      bash \
      git \
      openssh \
      nginx \
      libzip-dev \
      freetype \
      libjpeg-turbo \
      libpng \
      freetype-dev \
      libjpeg-turbo-dev \
      libpng-dev \
    && docker-php-ext-configure gd \
      --with-freetype=/usr/include/ \
      --with-jpeg=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-enable gd \
    && apk del --no-cache \
      freetype-dev \
      libjpeg-turbo-dev \
      libpng-dev \
    && rm -rf /tmp/*

RUN docker-php-ext-install pdo pdo_mysql zip bcmath pcntl opcache

# Nginx配置文件
COPY nginx/default.conf /etc/nginx/http.d/default.conf
# PHP配置文件
COPY php/php.ini /usr/local/etc/php/php.ini
COPY php/php-fpm.conf /usr/local/etc/php-fpm.conf
COPY php/php-fpm.d /usr/local/etc/php-fpm.d

RUN mkdir -p /var/log/php
RUN chown -R www-data:www-data /var/log/php

# 安装composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# 下载API程序代码
RUN git clone -b v4.9.5 https://github.com/Qsnh/meedu.git /var/www/api

# 设置工作目录
WORKDIR /var/www/api

# 安装依赖
RUN composer install --optimize-autoloader --no-dev

# 目录权限
RUN chown -R www-data:www-data /var/www/api

# laravel框架的一些操作
RUN php artisan route:cache && php artisan storage:link && php artisan install:lock

ENTRYPOINT nginx && php-fpm
