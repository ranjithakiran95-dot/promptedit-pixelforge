FROM node:22-bookworm-slim AS frontend

WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM php:8.3-cli-bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    git unzip libpq-dev libonig-dev libzip-dev \
    && docker-php-ext-install \
       bcmath mbstring pdo_mysql pdo_pgsql pcntl zip \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

WORKDIR /var/www/html
COPY . .

RUN composer install --no-dev --no-interaction \
    --prefer-dist --optimize-autoloader \
    && mkdir -p storage/framework/cache/data \
       storage/framework/sessions \
       storage/framework/views \
       storage/logs bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

COPY --from=frontend /app/public/build ./public/build

CMD ["sh", "/var/www/html/render-start.sh"]
