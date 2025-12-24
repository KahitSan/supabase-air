# Supabase Development Environment

This directory contains a complete Supabase development environment using Docker Compose with dashboard authentication and custom configurations.

## Recommended: Root-Level Startup

For the simplest experience, use the root-level startup script:

```bash
cd ..                   # Go to supabase-air root
./start.sh             # Interactive plan selection
./start.sh 4gb         # Start with 4GB plan
./start.sh unlimited   # Start without limits
./start.sh --reset     # Reset environment
```

The root `start.sh` script provides:
- Automatic first-time setup detection
- Interactive resource limit selection
- Simplified workflow for daily use

Continue reading below for docker-specific commands and advanced usage.

---

## 🚀 Quick Start

> **Recommended**: Use the root-level `../start.sh` script for simplest workflow.
> The instructions below are for when you're already in the docker/ directory.

### Prerequisites

- Docker Desktop installed and running
- Git (for version control)
- Basic familiarity with Docker Compose

### Initial Setup

1. **Clone and navigate to the project:**
   ```bash
   cd docker/
   ```

2. **Run the setup script:**
   ```bash
   ./setup.sh
   ```

   This will:
   - Check if Docker is running
   - Verify environment configuration
   - Pull the latest Docker images
   - Start all Supabase services
   - Show you the access URLs and credentials

3. **Access your services:**
   - **Dashboard**: http://localhost:8000 (requires login)
   - **Studio**: http://localhost:54323 (direct access)
   - **Database**: `postgresql://postgres:***@localhost:54322/postgres`
   - **API**: http://localhost:8000/rest/v1/
   - **Email Testing**: http://localhost:54324

## 🔐 Authentication

Your setup includes dashboard authentication for security:

- **Username**: `kahitsan`
- **Password**: Check your `.env` file for `DASHBOARD_PASSWORD`

## 📁 Project Structure

```
docker/
├── .env                 # Environment configuration (secured)
├── .env.example         # Template for environment variables
├── docker-compose.yml   # Main service definitions
├── setup.sh            # Initial setup script
├── reset.sh             # Database reset utility
├── dev-utils.sh         # Development utilities
├── volumes/             # Persistent data storage
│   ├── db/             # Database data and configs
│   ├── storage/        # File uploads
│   └── functions/      # Edge functions
└── README.md           # This file
```

## 🛠️ Development Commands

### Basic Operations

```bash
# Start services
./setup.sh

# View service status
./dev-utils.sh status

# View logs (all services)
./dev-utils.sh logs

# View logs (specific service)
./dev-utils.sh logs db

# Restart all services
./dev-utils.sh restart

# Restart specific service
./dev-utils.sh restart auth
```

### Database Operations

```bash
# Connect to database shell
./dev-utils.sh psql

# Open container shell
./dev-utils.sh shell

# Create backup
./dev-utils.sh backup

# Restore from backup
./dev-utils.sh restore

# Reset database (WARNING: destroys all data)
./reset.sh
```

### Maintenance

```bash
# Update to latest images
./dev-utils.sh update

# Clean up Docker resources
./dev-utils.sh clean

# Show environment info
./dev-utils.sh env

# Stop all services
docker compose down
```

## 🔧 Configuration

### Environment Variables

Key variables in `.env`:

- `DASHBOARD_USERNAME/PASSWORD` - Dashboard login credentials
- `POSTGRES_PASSWORD` - Database password
- `JWT_SECRET` - JWT signing secret
- `ANON_KEY/SERVICE_ROLE_KEY` - API access keys

### Custom Features

This setup includes:

- **Dashboard Authentication** - Secure access to admin panel
- **GitHub OAuth** - Pre-configured (requires client ID/secret)
- **Custom Schemas** - `public`, `content`, `storage`, `graphql_public`
- **File Storage** - Local file storage with custom buckets
- **Email Testing** - Inbucket for email development
- **Analytics** - Built-in logging and analytics

### Port Mapping

- `8000` - Kong API Gateway + Dashboard
- `54321` - Direct API access (if needed)
- `54322` - Direct database access
- `54323` - Supabase Studio
- `54324` - Email testing (Inbucket)
- `4000` - Analytics dashboard

## 🐛 Troubleshooting

### Common Issues

**Services won't start:**
```bash
# Check Docker is running
docker info

# View detailed logs
./dev-utils.sh logs

# Reset everything
./reset.sh
```

**Can't access dashboard:**
- Verify credentials in `.env` file
- Check if port 8000 is available
- Ensure all services are healthy: `./dev-utils.sh status`

**Database connection issues:**
```bash
# Test database connectivity
./dev-utils.sh psql

# Check database logs
./dev-utils.sh logs db

# Reset database volume
./reset.sh
```

**Port conflicts:**
- Modify ports in `.env` file
- Restart services: `./setup.sh`

### Logs and Debugging

```bash
# Follow all logs
./dev-utils.sh logs

# Specific service logs
./dev-utils.sh logs kong
./dev-utils.sh logs db
./dev-utils.sh logs auth

# Docker compose logs
docker compose logs -f [service_name]
```

## 🚀 Production Considerations

**⚠️ This setup is for development only!**

Before production:

1. **Change all default passwords and secrets**
2. **Use proper SSL certificates**
3. **Configure external database**
4. **Set up proper backup strategies**
5. **Review security configurations**
6. **Use environment-specific configs**

## 🤝 Team Development

### For New Developers

1. Clone the repository
2. Run `cd docker && ./setup.sh`
3. Wait for services to start
4. Access dashboard at http://localhost:8000

### Sharing Changes

- Environment changes: Update `.env.example`
- Service changes: Modify `docker-compose.yml`
- Always test with `./setup.sh` after changes

### Best Practices

- Use `./dev-utils.sh backup` before major changes
- Keep the `.env` file secure (never commit it)
- Use `./dev-utils.sh status` to verify service health
- Clean up regularly with `./dev-utils.sh clean`

## 📚 Additional Resources

- [Supabase Documentation](https://supabase.com/docs)
- [Docker Compose Reference](https://docs.docker.com/compose/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

## 🆘 Getting Help

If you encounter issues:

1. Check this README
2. Run `./dev-utils.sh status` for service health
3. Check logs with `./dev-utils.sh logs`
4. Try resetting with `./reset.sh`
5. Ask the team for help

---

**Happy coding! 🚀**
