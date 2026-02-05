# Magento 2 Installation Guide for Easypanel

This guide will walk you through installing Magento 2 on Easypanel using Docker Compose with official Magento Cloud Docker images.

## Prerequisites

- Easypanel installed and running on your server
- Domain name pointed to your server (optional but recommended)
- **Magento Marketplace Account** with Composer authentication keys
- At least 4GB RAM and 25GB disk space
- Server with Docker support

## Important: Get Your Magento Composer Keys

Before installation, you **MUST** obtain Composer authentication keys:

1. Go to https://marketplace.magento.com/
2. Sign in or create a free account
3. Navigate to **My Profile** → **Access Keys**
4. Click **Create A New Access Key**
5. Copy the **Public Key** and **Private Key**

These keys are required to download Magento from the official repository.

## Installation Steps

### Step 1: Prepare Your Repository

1. Clone or upload this repository to your Git provider (GitHub, GitLab, etc.)
2. Ensure the following files are in your repository:
   - `docker-compose.yml`
   - `nginx.conf`
   - `install-magento.sh`
   - `.env.example`

### Step 2: Create Project in Easypanel

1. Log in to your Easypanel dashboard
2. Click on **"Create Project"** or **"Add Service"**
3. Choose **"Docker Compose"** or **"Create from Source"**
4. If using Git:
   - Select **"Git Repository"**
   - Connect your Git provider and select this repository
5. Name your project (e.g., `magento2`)

### Step 3: Configure Environment Variables

In Easypanel, go to your project settings and add the following environment variables:

**Required Variables:**
```
MAGENTO_VERSION=2.4.7
BASE_URL=http://your-domain.com
ADMIN_FIRSTNAME=Admin
ADMIN_LASTNAME=User
ADMIN_EMAIL=admin@your-domain.com
ADMIN_USER=admin
ADMIN_PASSWORD=YourSecurePassword123!
MYSQL_HOST=mariadb
MYSQL_DATABASE=magento
MYSQL_USER=magento
MYSQL_PASSWORD=SecureDatabasePassword123!
MYSQL_ROOT_PASSWORD=SecureRootPassword123!
COMPOSER_AUTH_PUBLIC=your_magento_public_key
COMPOSER_AUTH_PRIVATE=your_magento_private_key
```

> **Critical:** Replace `COMPOSER_AUTH_PUBLIC` and `COMPOSER_AUTH_PRIVATE` with your actual Magento Marketplace keys!

### Step 4: Deploy the Containers

1. In Easypanel, click **"Deploy"** on your project
2. Wait for all containers to start (this pulls the images only)
3. Check that all services are running:
   - nginx
   - php
   - cli
   - mariadb
   - opensearch
   - redis

### Step 5: Run Magento Installation

After containers are running, you need to install Magento:

#### Option A: Using Easypanel Terminal

1. In Easypanel, access the **cli** service terminal
2. Run the installation script:
   ```bash
   cd /var/www/html
   chmod +x ../install-magento.sh
   ../install-magento.sh
   ```

#### Option B: Using SSH

1. SSH into your server
2. Find your project container:
   ```bash
   docker ps | grep cli
   ```
3. Execute the installation script:
   ```bash
   docker exec -it <cli_container_name> bash
   cd /var/www/html
   chmod +x ../install-magento.sh
   ../install-magento.sh
   ```

The installation process will:
- Download Magento via Composer (10-15 minutes)
- Install Magento with your configuration
- Configure OpenSearch for search
- Configure Redis for cache, page cache, and sessions
- Deploy static content
- Set developer mode
- Reindex all data

**Expected Installation Time:** 15-25 minutes depending on server speed

### Step 6: Configure Domain (Recommended)

1. In Easypanel, go to your project's **"Domains"** or **"Network"** section
2. Add your domain name to the **nginx** service
3. Enable SSL/HTTPS (Easypanel provides automatic Let's Encrypt certificates)
4. Update the `BASE_URL` environment variable to match your domain with https://
5. Update Magento base URLs:
   ```bash
   docker compose exec cli bash -c "cd /var/www/html && \
   php bin/magento setup:store-config:set --base-url='https://your-domain.com/' && \
   php bin/magento setup:store-config:set --base-url-secure='https://your-domain.com/' && \
   php bin/magento cache:flush"
   ```

### Step 7: Access Magento

**Frontend:**
- URL: `http://your-domain.com` or `http://your-server-ip`

**Admin Panel:**
- URL: `http://your-domain.com/admin` or `http://your-server-ip/admin`
- Username: The value you set in `ADMIN_USER` (default: `admin`)
- Password: The value you set in `ADMIN_PASSWORD`

### Step 8: Post-Installation Configuration

#### Set Up Cron Jobs (Important!)

Magento requires cron jobs for many operations. In Easypanel:

1. Add a **Cron Service** or use the cli container
2. Add this cron schedule:
   ```
   * * * * * docker exec <cli_container_name> bash -c "cd /var/www/html && php bin/magento cron:run"
   ```

Or run manually for testing:
```bash
docker compose exec cli bash -c "cd /var/www/html && php bin/magento cron:run"
```

#### Verify Configuration

```bash
# Check cache status
docker compose exec cli bash -c "cd /var/www/html && php bin/magento cache:status"

# Check OpenSearch connection
docker compose exec cli bash -c "cd /var/www/html && php bin/magento setup:db:status"

# Check Redis connection
docker compose exec redis redis-cli ping
```

## Architecture Overview

The Docker Compose setup includes:

- **Nginx** - Web server (Alpine Linux)
- **PHP-FPM** - PHP 8.2 with Magento Cloud Docker optimizations
- **CLI Container** - PHP 8.2 CLI for running Magento commands
- **MariaDB 10.6** - Database server
- **OpenSearch 2.11** - Search engine (required for Magento 2.4+)
- **Redis 7** - Cache and session storage

## Service Ports

- Nginx (HTTP): Port 80
- Nginx (HTTPS): Port 443
- PHP-FPM: Port 9000 (internal only)
- MariaDB: Port 3306 (internal only)
- OpenSearch: Port 9200 (internal only)
- Redis: Port 6379 (internal only)

## Persistent Data

The following volumes persist your data:

- `magento_data` - Magento application files
- `mariadb_data` - Database data
- `opensearch_data` - Search indices
- `redis_data` - Cache and session data
- `composer_cache` - Composer cache for faster operations

## Common Commands

All Magento commands should be run in the **cli** container:

```bash
# Access CLI container
docker compose exec cli bash
cd /var/www/html

# Clear cache
php bin/magento cache:flush

# Reindex
php bin/magento indexer:reindex

# Deploy static content
php bin/magento setup:static-content:deploy -f

# Compile DI
php bin/magento setup:di:compile

# Enable module
php bin/magento module:enable Vendor_Module

# Setup upgrade
php bin/magento setup:upgrade

# Switch to production mode
php bin/magento deploy:mode:set production
php bin/magento setup:static-content:deploy -f
php bin/magento setup:di:compile
```

## Troubleshooting

### Composer Authentication Failed

**Error:** "Could not authenticate against repo.magento.com"

**Solution:**
- Verify your Composer keys are correct
- Check that keys have no extra spaces
- Ensure keys are active in your Magento Marketplace account

### Installation Takes Too Long

- Magento download via Composer can take 10-15 minutes
- Installation process adds another 5-10 minutes
- Check the cli container logs for progress
- Ensure sufficient server resources (4GB+ RAM)

### Cannot Access Admin Panel

1. Verify the URL is correct: `http://your-domain.com/admin`
2. Check if installation completed successfully in logs
3. Clear cache:
   ```bash
   docker compose exec cli bash -c "cd /var/www/html && php bin/magento cache:flush"
   ```
4. Verify admin user was created:
   ```bash
   docker compose exec mariadb mysql -u magento -p -e "USE magento; SELECT * FROM admin_user;"
   ```

### OpenSearch Connection Failed

1. Check OpenSearch is running:
   ```bash
   docker compose ps opensearch
   ```
2. Test connection:
   ```bash
   docker compose exec opensearch curl http://localhost:9200/_cluster/health
   ```
3. Reconfigure in Magento:
   ```bash
   docker compose exec cli bash -c "cd /var/www/html && \
   php bin/magento config:set catalog/search/engine opensearch && \
   php bin/magento config:set catalog/search/opensearch_server_hostname opensearch && \
   php bin/magento config:set catalog/search/opensearch_server_port 9200 && \
   php bin/magento cache:flush && \
   php bin/magento indexer:reindex"
   ```

### Slow Performance

1. Ensure sufficient resources (minimum 4GB RAM, 2 CPU cores)
2. Enable production mode:
   ```bash
   docker compose exec cli bash -c "cd /var/www/html && \
   php bin/magento deploy:mode:set production && \
   php bin/magento setup:di:compile && \
   php bin/magento setup:static-content:deploy -f"
   ```
3. Verify Redis is being used:
   ```bash
   docker compose exec redis redis-cli monitor
   # Visit your site and check for Redis activity
   ```

### Permission Issues

```bash
docker compose exec cli bash -c "cd /var/www/html && \
find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} + && \
find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} +"
```

### Reset Installation

If you need to start fresh:

1. Stop all containers:
   ```bash
   docker compose down
   ```
2. Remove all volumes (⚠️ This will erase ALL data):
   ```bash
   docker volume rm $(docker volume ls -q | grep magento)
   ```
3. Restart and run installation again:
   ```bash
   docker compose up -d
   ./install-magento.sh
   ```

## Backup Recommendations

Regular backups are essential:

1. **Database backup:**
   ```bash
   docker compose exec mariadb mysqldump -u magento -p magento > backup_$(date +%Y%m%d).sql
   ```

2. **Files backup:**
   ```bash
   docker compose exec cli tar -czf /tmp/magento_backup.tar.gz -C /var/www/html .
   docker cp $(docker compose ps -q cli):/tmp/magento_backup.tar.gz ./magento_backup_$(date +%Y%m%d).tar.gz
   ```

3. **Restore database:**
   ```bash
   docker compose exec -T mariadb mysql -u magento -p magento < backup_20250206.sql
   ```

## Updating Magento

To update Magento version:

1. Backup your installation first!
2. Update via Composer:
   ```bash
   docker compose exec cli bash -c "cd /var/www/html && \
   composer require magento/product-community-edition=2.4.8 --no-update && \
   composer update && \
   php bin/magento setup:upgrade && \
   php bin/magento setup:di:compile && \
   php bin/magento setup:static-content:deploy -f && \
   php bin/magento cache:flush"
   ```

## Security Best Practices

1. **Always use strong passwords** for all services
2. **Enable HTTPS** through Easypanel's SSL configuration
3. **Change admin URL** from `/admin` to something custom:
   ```bash
   php bin/magento setup:config:set --backend-frontname="custom_admin_url"
   ```
4. **Enable 2FA** for admin users (disable the module disable in install script for production)
5. **Keep Magento and all dependencies updated**
6. **Regular backups** of database and files
7. **Use environment variables** for sensitive data, never commit credentials
8. **Restrict database access** to only necessary containers

## Additional Resources

- [Magento 2 Documentation](https://experienceleague.adobe.com/docs/commerce.html)
- [Magento Cloud Docker](https://github.com/magento/magento-cloud-docker)
- [Magento Marketplace](https://marketplace.magento.com/)
- [Easypanel Documentation](https://easypanel.io/docs)

## Support

For Magento-specific issues, consult:
- Official Magento documentation
- Magento Stack Exchange: https://magento.stackexchange.com/
- Magento Community Forums

For Easypanel deployment issues, refer to Easypanel documentation or support channels.
