# NetBox + Nautobot Home-Lab Stack

A production-ready Docker Compose stack that deploys NetBox and Nautobot side-by-side on a home network with Traefik for routing, persistent volumes, health checks, and bootstrap superuser support.

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose
- Make
- OpenSSL
- Ubuntu VM on your LAN (e.g., 192.168.5.9)

### Setup

1. **Clone and initialize:**
   ```bash
   git clone <your-repo>
   cd network-automation-stack-v3
   make init
   ```

2. **Configure (optional):**
   ```bash
   # Edit .env file if you need to change defaults
   nano .env
   ```

3. **Start the stack:**
   ```bash
   make up
   ```

4. **Access the applications:**
   - NetBox: http://netbox.home
   - Nautobot: http://nautobot.home

## 📋 Configuration

### Environment Variables

The stack uses a `.env` file for configuration. Default values:

```bash
# Server Configuration
SERVER_IP=192.168.5.9
NETBOX_HOST=netbox.home
NAUTOBOT_HOST=nautobot.home

# Database Configuration
POSTGRES_USER=netops
POSTGRES_PASSWORD=CHANGE_ME_STRONG
NETBOX_DB=netbox
NAUTOBOT_DB=nautobot

# NetBox Configuration
NETBOX_SECRET_KEY=to_be_generated  # Auto-generated on first run
NETBOX_SUPERUSER_NAME=admin
NETBOX_SUPERUSER_EMAIL=admin@example.com
NETBOX_SUPERUSER_PASSWORD=CHANGE_ME_STRONG
NETBOX_ALLOWED_HOSTS=*,localhost,127.0.0.1,${SERVER_IP},${NETBOX_HOST}

# Nautobot Configuration
NAUTOBOT_SECRET_KEY=to_be_generated  # Auto-generated on first run
NAUTOBOT_SUPERUSER_NAME=admin
NAUTOBOT_SUPERUSER_EMAIL=admin@example.com
NAUTOBOT_SUPERUSER_PASSWORD=CHANGE_ME_STRONG
NAUTOBOT_ALLOWED_HOSTS=*,localhost,127.0.0.1,${SERVER_IP},${NAUTOBOT_HOST}
```

### DNS Configuration

Add these A records to your home DNS (Pi-hole, router, etc.):

```
netbox.home    → 192.168.5.9
nautobot.home  → 192.168.5.9
```

Or add to `/etc/hosts` on your clients:

```
192.168.5.9 netbox.home nautobot.home
```

## 🛠️ Management Commands

### Basic Operations

```bash
make up          # Start the entire stack
make down        # Stop the entire stack
make restart     # Restart applications
make logs        # Show logs from all services
make status      # Show container status
make health      # Check health of all services
```

### User Management

```bash
make nb-admin    # Create NetBox superuser (interactive)
make na-admin    # Create Nautobot superuser (from .env)
```

### Development

```bash
make dev-logs SERVICE=netbox     # Show logs from specific service
make dev-shell SERVICE=netbox    # Open shell in specific service
```

### Backup & Restore

```bash
make backup                           # Create backup
make restore BACKUP_DATE=20240101_120000  # Restore from backup
```

## 🏗️ Architecture

### Services

- **reverse-proxy** (Traefik v3): Routes traffic to NetBox/Nautobot
- **postgres** (PostgreSQL 17): Shared database server
- **redis** (Valkey 8.1): NetBox session storage
- **redis-cache** (Valkey 8.1): NetBox cache storage
- **netbox**: NetBox v4.4-3.4.0 application
- **netbox-worker**: NetBox background worker
- **nautobot**: Nautobot v2.3 application
- **nautobot-worker**: Nautobot background worker

### Networks

All services run on a user-defined bridge network `netmgmt` for isolation.

### Volumes

- `pg-data`: PostgreSQL data
- `netbox-media-files`: NetBox media files
- `netbox-scripts-files`: NetBox scripts
- `netbox-reports-files`: NetBox reports
- `netbox-redis-data`: NetBox Redis data
- `netbox-redis-cache-data`: NetBox Redis cache data
- `nautobot-media`: Nautobot media files

## 🔧 Advanced Configuration

### Traefik Configuration

Traefik configuration is in `traefik/`:
- `traefik.yml`: Static configuration
- `dynamic.yml`: Dynamic configuration (placeholder)

### Database Initialization

The PostgreSQL container automatically creates the required databases and extensions via `scripts/init-db.sql`.

### Health Checks

All services include health checks:
- PostgreSQL: `pg_isready`
- Redis: `valkey-cli ping`
- NetBox: HTTP GET to `/login/`
- Nautobot: HTTP GET to `/`

## 🐛 Troubleshooting

### Common Issues

1. **Services not starting:**
   ```bash
   make logs
   docker compose ps
   ```

2. **Database connection issues:**
   ```bash
   make health
   ```

3. **Permission issues:**
   ```bash
   sudo chown -R $USER:$USER .
   ```

4. **Port conflicts:**
   ```bash
   # Check what's using port 80
   sudo netstat -tlnp | grep :80
   ```

### Logs

```bash
# All services
make logs

# Specific service
make dev-logs SERVICE=netbox

# Follow logs
docker compose logs -f netbox
```

### Database Access

```bash
# Connect to PostgreSQL
docker compose exec postgres psql -U netops

# List databases
docker compose exec postgres psql -U netops -c "\l"

# Connect to specific database
docker compose exec postgres psql -U netops -d netbox
```

## 🔒 Security Notes

- Change default passwords in `.env`
- Consider enabling HTTPS with Let's Encrypt
- Restrict `ALLOWED_HOSTS` to your specific domains
- Use strong database passwords
- Regularly backup your data

## 📚 Additional Resources

- [NetBox Documentation](https://docs.netbox.dev/)
- [Nautobot Documentation](https://docs.nautobot.com/)
- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

If you encounter issues:

1. Check the troubleshooting section
2. Review the logs
3. Check the GitHub issues
4. Create a new issue with detailed information

---

**Happy networking! 🚀**
