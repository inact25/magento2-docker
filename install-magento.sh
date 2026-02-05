#!/bin/bash

# Magento 2 Installation Script
# This script installs Magento 2 in the Docker environment

set -e

echo "=========================================="
echo "Magento 2 Installation Script"
echo "=========================================="

# Load environment variables
if [ -f .env ]; then
    source .env
else
    echo "Error: .env file not found. Please copy .env.example to .env and configure it."
    exit 1
fi

# Set defaults if not provided
MAGENTO_VERSION="${MAGENTO_VERSION:-2.4.7}"
BASE_URL="${BASE_URL:-http://localhost}"
ADMIN_FIRSTNAME="${ADMIN_FIRSTNAME:-Admin}"
ADMIN_LASTNAME="${ADMIN_LASTNAME:-User}"
ADMIN_EMAIL="${ADMIN_EMAIL:-admin@example.com}"
ADMIN_USER="${ADMIN_USER:-admin}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-Admin@123}"
MYSQL_HOST="${MYSQL_HOST:-mariadb}"
MYSQL_DATABASE="${MYSQL_DATABASE:-magento}"
MYSQL_USER="${MYSQL_USER:-magento}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-magento_password}"
COMPOSER_AUTH_PUBLIC="${COMPOSER_AUTH_PUBLIC}"
COMPOSER_AUTH_PRIVATE="${COMPOSER_AUTH_PRIVATE}"

echo "Starting containers..."
docker compose up -d

echo "Waiting for MariaDB to be ready..."
sleep 10

echo "Checking if Magento is already installed..."
if docker compose exec -T cli test -f /var/www/html/app/etc/env.php; then
    echo "Magento is already installed. Skipping installation."
    exit 0
fi

echo "Installing Magento ${MAGENTO_VERSION}..."

# Set Composer authentication if provided
if [ ! -z "$COMPOSER_AUTH_PUBLIC" ] && [ ! -z "$COMPOSER_AUTH_PRIVATE" ]; then
    echo "Setting up Composer authentication..."
    docker compose exec -T cli composer global config http-basic.repo.magento.com "$COMPOSER_AUTH_PUBLIC" "$COMPOSER_AUTH_PRIVATE"
fi

echo "Downloading Magento via Composer..."
docker compose exec -T cli bash -c "cd /var/www/html && composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition:${MAGENTO_VERSION} ."

echo "Setting permissions..."
docker compose exec -T cli bash -c "cd /var/www/html && find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} + && find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} +"

echo "Installing Magento..."
docker compose exec -T cli bash -c "cd /var/www/html && php bin/magento setup:install \
    --base-url=${BASE_URL} \
    --db-host=${MYSQL_HOST} \
    --db-name=${MYSQL_DATABASE} \
    --db-user=${MYSQL_USER} \
    --db-password=${MYSQL_PASSWORD} \
    --admin-firstname=${ADMIN_FIRSTNAME} \
    --admin-lastname=${ADMIN_LASTNAME} \
    --admin-email=${ADMIN_EMAIL} \
    --admin-user=${ADMIN_USER} \
    --admin-password=${ADMIN_PASSWORD} \
    --language=en_US \
    --currency=USD \
    --timezone=America/Chicago \
    --use-rewrites=1 \
    --search-engine=opensearch \
    --opensearch-host=opensearch \
    --opensearch-port=9200 \
    --opensearch-index-prefix=magento2 \
    --opensearch-timeout=15"

echo "Configuring Redis for cache..."
docker compose exec -T cli bash -c "cd /var/www/html && php bin/magento setup:config:set --cache-backend=redis --cache-backend-redis-server=redis --cache-backend-redis-db=0"

echo "Configuring Redis for page cache..."
docker compose exec -T cli bash -c "cd /var/www/html && php bin/magento setup:config:set --page-cache=redis --page-cache-redis-server=redis --page-cache-redis-db=1"

echo "Configuring Redis for sessions..."
docker compose exec -T cli bash -c "cd /var/www/html && php bin/magento setup:config:set --session-save=redis --session-save-redis-host=redis --session-save-redis-db=2"

echo "Disabling two-factor authentication (for development)..."
docker compose exec -T cli bash -c "cd /var/www/html && php bin/magento module:disable Magento_AdminAdobeImsTwoFactorAuth Magento_TwoFactorAuth"

echo "Setting up cron..."
docker compose exec -T cli bash -c "cd /var/www/html && php bin/magento cron:install"

echo "Deploying static content..."
docker compose exec -T cli bash -c "cd /var/www/html && php bin/magento setup:static-content:deploy -f"

echo "Setting developer mode..."
docker compose exec -T cli bash -c "cd /var/www/html && php bin/magento deploy:mode:set developer"

echo "Reindexing..."
docker compose exec -T cli bash -c "cd /var/www/html && php bin/magento indexer:reindex"

echo "Flushing cache..."
docker compose exec -T cli bash -c "cd /var/www/html && php bin/magento cache:flush"

echo "=========================================="
echo "Magento 2 Installation Complete!"
echo "=========================================="
echo "Frontend: ${BASE_URL}"
echo "Admin Panel: ${BASE_URL}/admin"
echo "Admin Username: ${ADMIN_USER}"
echo "Admin Password: ${ADMIN_PASSWORD}"
echo "=========================================="
