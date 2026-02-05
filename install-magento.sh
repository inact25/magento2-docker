#!/bin/bash

# Magento 2 Installation Script
set -e

echo "=========================================="
echo "Magento 2 Installation"
echo "=========================================="

# Check required environment variables
if [ -z "$COMPOSER_AUTH_PUBLIC" ] || [ -z "$COMPOSER_AUTH_PRIVATE" ]; then
    echo "Error: COMPOSER_AUTH_PUBLIC and COMPOSER_AUTH_PRIVATE must be set"
    echo "Get your keys from https://marketplace.magento.com/customer/accessKeys/"
    exit 1
fi

# Set defaults
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

cd /var/www/html

# Check if already installed
if [ -f app/etc/env.php ]; then
    echo "Magento already installed!"
    exit 0
fi

echo "Waiting for MariaDB..."
until nc -z -w30 $MYSQL_HOST 3306; do
    echo "Waiting for database..."
    sleep 5
done

echo "Waiting for OpenSearch..."
until curl -s http://opensearch:9200/_cluster/health > /dev/null; do
    echo "Waiting for OpenSearch..."
    sleep 5
done

# Set up Composer auth
echo "Configuring Composer authentication..."
mkdir -p ~/.composer
composer config -g http-basic.repo.magento.com "$COMPOSER_AUTH_PUBLIC" "$COMPOSER_AUTH_PRIVATE"

# Check if directory is empty (except hidden files we just created)
if [ "$(ls -A | grep -v '^\.composer$' | wc -l)" -gt 0 ]; then
    echo "Directory not empty, downloading to temp location..."
    cd /tmp
    composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition:${MAGENTO_VERSION} magento --no-install
    cd magento
    shopt -s dotglob nullglob
    mv * /var/www/html/
    cd /var/www/html
    rm -rf /tmp/magento
else
    echo "Downloading Magento ${MAGENTO_VERSION}..."
    composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition:${MAGENTO_VERSION} . --no-install
fi

echo "Installing Composer dependencies..."
composer install

echo "Setting permissions..."
find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} + 2>/dev/null || true
find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} + 2>/dev/null || true
chmod +x bin/magento

echo "Installing Magento..."
php bin/magento setup:install \
    --base-url="${BASE_URL}" \
    --db-host="${MYSQL_HOST}" \
    --db-name="${MYSQL_DATABASE}" \
    --db-user="${MYSQL_USER}" \
    --db-password="${MYSQL_PASSWORD}" \
    --admin-firstname="${ADMIN_FIRSTNAME}" \
    --admin-lastname="${ADMIN_LASTNAME}" \
    --admin-email="${ADMIN_EMAIL}" \
    --admin-user="${ADMIN_USER}" \
    --admin-password="${ADMIN_PASSWORD}" \
    --language=en_US \
    --currency=USD \
    --timezone=America/Chicago \
    --use-rewrites=1 \
    --search-engine=opensearch \
    --opensearch-host=opensearch \
    --opensearch-port=9200 \
    --opensearch-index-prefix=magento2 \
    --opensearch-timeout=15

echo "Configuring Redis..."
php bin/magento setup:config:set --cache-backend=redis --cache-backend-redis-server=redis --cache-backend-redis-db=0
php bin/magento setup:config:set --page-cache=redis --page-cache-redis-server=redis --page-cache-redis-db=1
php bin/magento setup:config:set --session-save=redis --session-save-redis-host=redis --session-save-redis-db=2

echo "Disabling 2FA..."
php bin/magento module:disable Magento_AdminAdobeImsTwoFactorAuth Magento_TwoFactorAuth || true

echo "Deploying static content..."
php bin/magento setup:static-content:deploy -f

echo "Setting developer mode..."
php bin/magento deploy:mode:set developer

echo "Reindexing..."
php bin/magento indexer:reindex

echo "Flushing cache..."
php bin/magento cache:flush

echo "Setting final permissions..."
chown -R www-data:www-data /var/www/html
find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} + 2>/dev/null || true
find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} + 2>/dev/null || true

echo "=========================================="
echo "Installation Complete!"
echo "Frontend: ${BASE_URL}"
echo "Admin: ${BASE_URL}/admin"
echo "Username: ${ADMIN_USER}"
echo "Password: ${ADMIN_PASSWORD}"
echo "=========================================="
