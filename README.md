# Magento 2 Docker Compose for Easypanel

This repository contains a production-ready Docker Compose configuration for running Magento 2 on Easypanel using custom-built PHP containers with all required extensions.

## ⚡ Quick Start

### Prerequisites

1. **Magento Marketplace Account** - Get free Composer authentication keys:
   - Go to https://marketplace.magento.com/
   - Navigate to **My Profile** → **Access Keys**
   - Create a new access key (Public Key = username, Private Key = password)

2. **System Requirements:**
   - Docker and Docker Compose v2+
   - Minimum 4GB RAM
   - 25GB free disk space

### For Easypanel Deployment

📖 **Quick Setup:** [EASYPANEL_SETUP.md](EASYPANEL_SETUP.md) - Start here!
📖 **Detailed Guide:** [EASYPANEL_INSTALLATION_GUIDE.md](EASYPANEL_INSTALLATION_GUIDE.md)

**Quick Steps:**
1. Get Magento Composer keys from https://marketplace.magento.com/
2. Push this repository to Git
3. Create project in Easypanel from Git repository
4. Add environment variables (see `.env.example`)
5. **Critical:** Add your Composer authentication:
   - `COMPOSER_AUTH_PUBLIC=your_public_key`
   - `COMPOSER_AUTH_PRIVATE=your_private_key`
6. Deploy (builds custom PHP images - takes 5-10 minutes)
7. Configure domain in Easypanel's Domain/Network settings (not in docker-compose.yml)
8. Access CLI container terminal and run: `bash /install-magento.sh`
9. Wait 15-25 minutes for Magento installation

### For Local Development

1. **Copy the environment file:**
   ```bash
   cp .env.example .env
   ```

2. **Edit `.env` and add your Magento Composer keys:**
   ```env
   COMPOSER_AUTH_PUBLIC=your_public_key
   COMPOSER_AUTH_PRIVATE=your_private_key
   ```

3. **Start the containers:**
   ```bash
   docker compose up -d --build
   ```
   *First build takes 5-10 minutes to build PHP images*

4. **Run the installation script:**
   ```bash
   docker compose exec cli bash /install-magento.sh
   ```

5. **Wait 15-25 minutes** for installation to complete

6. **Access Magento:**
   - Frontend: http://localhost
   - Admin: http://localhost/admin
   - Username: admin
   - Password: Admin@123 (change in .env)

## 🏗️ What's Included

- **Nginx** - High-performance web server (Alpine Linux)
- **PHP 8.2 FPM** - Custom-built with all Magento required extensions
- **PHP 8.2 CLI** - Separate container for running Magento commands
- **MariaDB 10.6** - Optimized database server
- **OpenSearch 2.11** - Search engine (Magento 2.4+ requirement)
- **Redis 7** - Cache and session storage

### PHP Extensions Included
- PDO MySQL, MySQLi
- GD (with FreeType, JPEG, WebP)
- Intl, SOAP, XSL
- ZIP, BCMath, Sockets
- Sodium, OPcache

## 📋 Common Commands

All Magento commands should be run in the **cli** container:

```bash
# Access CLI container
docker compose exec cli bash

# Clear cache
php bin/magento cache:flush

# Reindex
php bin/magento indexer:reindex

# Deploy static content
php bin/magento setup:static-content:deploy -f

# Switch to production mode
php bin/magento deploy:mode:set production
php bin/magento setup:di:compile
php bin/magento setup:static-content:deploy -f
```

See [QUICK_REFERENCE.md](QUICK_REFERENCE.md) for more commands.

## 📚 Documentation

- **[EASYPANEL_SETUP.md](EASYPANEL_SETUP.md)** - ⚡ Quick Easypanel setup (start here!)
- **[EASYPANEL_INSTALLATION_GUIDE.md](EASYPANEL_INSTALLATION_GUIDE.md)** - Complete detailed guide
- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - Handy command reference
- **[CLAUDE.md](CLAUDE.md)** - Development guidelines and architecture overview
- **[CHANGELOG.md](CHANGELOG.md)** - Version history and changes

## 🔧 Project Structure

```
.
├── docker-compose.yml          # Docker services configuration
├── Dockerfile.php              # PHP-FPM image with Magento extensions
├── Dockerfile.cli              # PHP CLI image for commands
├── nginx.conf                  # Nginx configuration for Magento
├── install-magento.sh          # Automated installation script
├── .env.example                # Environment variables template
├── EASYPANEL_INSTALLATION_GUIDE.md
├── QUICK_REFERENCE.md
└── CLAUDE.md
```

## 🚀 Key Features

- **Custom PHP Images** - Built with all Magento required extensions
- **Optimized Configuration** - Pre-configured for best performance
- **OpenSearch Integration** - Modern search engine support
- **Redis Caching** - Fast cache and session storage
- **Automated Installation** - One-command setup script
- **Production Ready** - Secure and scalable configuration
- **Easypanel Optimized** - Designed specifically for Easypanel deployment
- **No External Image Dependencies** - Builds from official PHP images

## ⚠️ Important Notes

1. **Composer Keys Required** - You MUST have Magento Marketplace authentication keys
2. **First Build Takes Time** - Initial build (5-10 min) + Magento install (15-25 min)
3. **Resource Requirements** - Ensure your server has at least 4GB RAM
4. **Production Deployment** - Change all default passwords before going live

## 🐛 Troubleshooting

### Port Already Allocated Error (Easypanel)
✅ **Fixed!** The docker-compose.yml uses `expose` instead of `ports`.
👉 Configure domain routing in **Easypanel's Domain settings**, not in docker-compose.yml

### Docker Build Fails
- Ensure stable internet connection for downloading packages
- Check Docker has sufficient disk space
- Try: `docker compose build --no-cache`

### Installation Script Fails
1. Check Composer keys are correct (no extra spaces!)
2. Verify all containers are running: `docker compose ps`
3. Check MariaDB is ready: `docker compose logs mariadb`
4. Check OpenSearch is ready: `docker compose logs opensearch`

### Cannot Access Website
1. **Easypanel:** Verify domain is configured in Domain/Network settings
2. Check nginx logs: `docker compose logs nginx`
3. Check PHP logs: `docker compose logs php`
4. Verify installation completed: `docker compose exec cli ls -la /var/www/html/app/etc/env.php`

For more solutions, see [EASYPANEL_SETUP.md](EASYPANEL_SETUP.md#troubleshooting)

## 📦 System Requirements

**Minimum:**
- 4GB RAM
- 2 CPU cores
- 25GB disk space
- Docker Engine 20.10+
- Docker Compose v2+

**Recommended:**
- 8GB RAM
- 4 CPU cores
- 50GB SSD storage

## 🔒 Security

- Change all default passwords in `.env`
- Enable HTTPS in production
- Change admin URL from `/admin`
- Enable 2FA for admin users
- Keep all components updated
- Regular backups

## 📄 License

This Docker configuration is provided as-is for deploying Magento 2. Magento 2 itself is licensed under OSL 3.0.

## 🤝 Support

- **Magento Issues:** https://experienceleague.adobe.com/docs/commerce.html
- **Stack Exchange:** https://magento.stackexchange.com/
- **Easypanel:** https://easypanel.io/docs

---

**Need help?** Check the [comprehensive installation guide](EASYPANEL_INSTALLATION_GUIDE.md) or [troubleshooting section](EASYPANEL_INSTALLATION_GUIDE.md#troubleshooting).
