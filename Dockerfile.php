FROM php:8.2-fpm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    libicu-dev \
    libxslt-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libwebp-dev \
    libsodium-dev \
    zip \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions required by Magento
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j$(nproc) \
    pdo_mysql \
    mysqli \
    gd \
    intl \
    soap \
    xsl \
    zip \
    bcmath \
    sockets \
    sodium \
    opcache

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set PHP configuration for Magento
RUN echo "memory_limit = 2G" > /usr/local/etc/php/conf.d/magento.ini \
    && echo "max_execution_time = 18000" >> /usr/local/etc/php/conf.d/magento.ini \
    && echo "zlib.output_compression = On" >> /usr/local/etc/php/conf.d/magento.ini \
    && echo "opcache.enable = 1" >> /usr/local/etc/php/conf.d/magento.ini \
    && echo "opcache.memory_consumption = 512" >> /usr/local/etc/php/conf.d/magento.ini \
    && echo "opcache.max_accelerated_files = 60000" >> /usr/local/etc/php/conf.d/magento.ini \
    && echo "opcache.consistency_checks = 0" >> /usr/local/etc/php/conf.d/magento.ini \
    && echo "opcache.validate_timestamps = 0" >> /usr/local/etc/php/conf.d/magento.ini

# Set working directory
WORKDIR /var/www/html

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html

USER www-data

EXPOSE 9000
