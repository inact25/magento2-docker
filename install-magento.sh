#!/bin/bash

# Magento 2 Installation Script
# This script installs Magento 2 in the Docker environment

set -e

echo "=========================================="
echo "Magento 2 Installation Script"
echo "=========================================="

# Check if running inside container
if [ ! -f /.dockerenv ] && [ ! -f /run/.containerenv ]; then
    echo "This script should be run inside the CLI container."
    echo "Run: docker compose exec cli bash /install-magento.sh"
    exit 1
fi

# Check required environment variables
if [ -z "$COMPOSER_AUTH_PUBLIC" ] || [ -z "$COMPOSER_AUTH_PRIVATE" ]; then
    echo "Error: COMPOSER_AUTH_PUBLIC and COMPOSER_AUTH_PRIVATE must be set"
    echo "Get your keys from https://marketplace.magento.com/customer/accessKeys/"
    exit 1
fi

# Set defaults from environment variables
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

echo "Checking if Magento is already installed..."
if [ -f /var/www/html/app/etc/env.php ]; then
    echo "Magento is already installed. Skipping installation."
    exit 0
fi

echo "Waiting for MariaDB to be ready..."
until nc -z -v -w30 $MYSQL_HOST 3306
do
    echo "Waiting for database connection..."
    sleep 5
done
echo "Database is ready!"

echo "Waiting for OpenSearch to be ready..."
until curl -s http://opensearch:9200/_cluster/health > /dev/null
do
    echo "Waiting for OpenSearch..."
    sleep 5
done
echo "OpenSearch is ready!"

echo "Setting up Composer authentication..."
composer global config http-basic.repo.magento.com "$COMPOSER_AUTH_PUBLIC" "$COMPOSER_AUTH_PRIVATE"

echo "Downloading Magento ${MAGENTO_VERSION} via Composer..."
echo "This may take 10-15 minutes..."
cd /var/www/html
composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition:${MAGENTO_VERSION} . --no-install

echo "Installing Composer dependencies..."
composer install

echo "Setting permissions..."
find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} + 2>/dev/null || true
find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} + 2>/dev/null || true
chmod +x bin/magento

echo "Installing Magento..."
php bin/magento setup:install \
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
    --opensearch-timeout=15

echo "Configuring Redis for cache..."
php bin/magento setup:config:set \
    --cache-backend=redis \
    --cache-backend-redis-server=redis \
    --cache-backend-redis-db=0

echo "Configuring Redis for page cache..."
php bin/magento setup:config:set \
    --page-cache=redis \
    --page-cache-redis-server=redis \
    --page-cache-redis-db=1

echo "Configuring Redis for sessions..."
php bin/magento setup:config:set \
    --session-save=redis \
    --session-save-redis-host=redis \
    --session-save-redis-db=2

echo "Disabling two-factor authentication (for development)..."
php bin/magento module:disable Magento_AdminAdobeImsTwoFactorAuth Magento_TwoFactorAuth || true

echo "Setting up cron..."
php bin/magento cron:install || true

echo "Deploying static content..."
php bin/magento setup:static-content:deploy -f

echo "Setting developer mode..."
php bin/magento deploy:mode:set developer

echo "Reindexing..."
php bin/magento indexer:reindex

echo "Flushing cache..."
php bin/magento cache:flush

echo "Setting final permissions..."
find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} + 2>/dev/null || true
find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} + 2>/dev/null || true

echo "=========================================="
echo "Magento 2 Installation Complete!"
echo "=========================================="
echo "Frontend: ${BASE_URL}"
echo "Admin Panel: ${BASE_URL}/admin"
echo "Admin Username: ${ADMIN_USER}"
echo "Admin Password: ${ADMIN_PASSWORD}"
echo "=========================================="
