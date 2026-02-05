# Magento 2 Docker Compose for Easypanel

This repository contains a Docker Compose configuration for running Magento 2 on Easypanel.

## Quick Start

### For Easypanel Deployment

Follow the comprehensive guide in [EASYPANEL_INSTALLATION_GUIDE.md](EASYPANEL_INSTALLATION_GUIDE.md)

### For Local Development

1. Copy the environment file:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` with your configuration

3. Start the containers:
   ```bash
   docker-compose up -d
   ```

4. Wait for installation to complete (5-10 minutes)

5. Access Magento:
   - Frontend: http://localhost
   - Admin: http://localhost/admin

## What's Included

- **Magento 2.4** with PHP-FPM and Nginx
- **MariaDB 10.6** for database
- **OpenSearch 7.17** for search (required for Magento 2.4+)
- **Redis 7** for caching and sessions

## System Requirements

- Docker and Docker Compose
- Minimum 4GB RAM
- 20GB free disk space

## Documentation

- [Easypanel Installation Guide](EASYPANEL_INSTALLATION_GUIDE.md) - Complete guide for Easypanel deployment
- [CLAUDE.md](CLAUDE.md) - Development guidelines and Magento CLI commands

## Default Credentials

**Admin Panel:**
- URL: http://localhost/admin
- Username: admin
- Password: admin123

> **Important:** Change these credentials in production!

## Support

For issues and questions:
- Magento 2: https://devdocs.magento.com/
- Easypanel: https://easypanel.io/docs

## License

This Docker configuration is provided as-is for deploying Magento 2. Magento 2 itself is licensed under OSL 3.0.
