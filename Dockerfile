FROM php:8.2-apache

WORKDIR /var/www/html
COPY . /var/www/html

# install system dependencies + PHP extensions
RUN apt-get update && \
    apt-get install -y \
       libzip-dev \
       unzip \
       git \
       libpng-dev \
       libjpeg-dev \
       libfreetype6-dev \
    && docker-php-ext-configure gd \
         --with-freetype=/usr/include/ \
         --with-jpeg=/usr/include/ \
    && docker-php-ext-install \
         zip \
         pdo \
         pdo_mysql \
         gd \
    && rm -rf /var/lib/apt/lists/*

# install Composer
RUN curl -sS https://getcomposer.org/installer \
      | php -- --install-dir=/usr/local/bin --filename=composer

# Laravel setup
RUN composer install --no-interaction --prefer-dist --optimize-autoloader \
 && php artisan storage:link

EXPOSE 8000
CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]
