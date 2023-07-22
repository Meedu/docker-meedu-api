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

# 安装 Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# 设置工作目录
WORKDIR /var/www

# 复制 Laravel 项目文件到工作目录
COPY /api /var/www

# 安装项目依赖
RUN composer install --optimize-autoloader --no-dev

# 设置文件权限
RUN chown -R www-data:www-data /var/www /var/www/bootstrap/cache

# 复制 Nginx 配置文件
COPY nginx/default.conf /etc/nginx/http.d/default.conf

# 启动 Nginx 和 PHP-FPM
ENTRYPOINT nginx && php-fpm
