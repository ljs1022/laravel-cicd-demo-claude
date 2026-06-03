# ================================
# Stage 1: builder
# 只負責安裝 Composer 依賴
# ================================
FROM composer:2 AS builder

WORKDIR /app

# 先複製依賴定義檔
COPY composer.json composer.lock ./

# 安裝依賴（不含 dev 套件）
RUN composer install \
    --no-dev \
    --no-scripts \
    --no-autoloader \
    --prefer-dist

# 再複製程式碼
COPY . .

# 產生 autoloader
RUN composer dump-autoload --optimize --no-dev

# ================================
# Stage 2: production
# 正式執行環境
# ================================
FROM php:8.2-fpm AS production

# 安裝系統依賴
# 安裝系統依賴
RUN apt-get update && apt-get install -y \
    libzip-dev \
    libxml2-dev \
    libonig-dev \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 安裝 PHP 擴充套件
RUN docker-php-ext-install \
    bcmath \
    ctype \
    fileinfo \
    mbstring \
    opcache \
    xml \
    zip

# 設定 OPcache
RUN echo "opcache.enable=1" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.memory_consumption=128" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.max_accelerated_files=10000" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.validate_timestamps=0" >> /usr/local/etc/php/conf.d/opcache.ini

WORKDIR /var/www/html

# 從 builder 複製程式碼和依賴
COPY --from=builder /app .

# 設定檔案權限
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/storage \
    && chmod -R 755 /var/www/html/bootstrap/cache

USER www-data

EXPOSE 9000

CMD ["php-fpm"]
