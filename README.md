# Supabase Self-Hosted Infrastructure

Optimized Docker Compose setup for self-hosting Supabase with reduced resource usage. Suitable for both production and development environments.

> **Based on**: [supabase/supabase](https://github.com/supabase/supabase) - The official Supabase repository
> **Supabase Version**: Studio 2025.06.30 | PostgreSQL 15.8.1.060

---

## What's Different from Official Supabase?

This repository is an **optimized fork** of the official Supabase self-hosting setup with the following customizations:

### 🎯 Key Changes

| Feature | Details |
|---------|---------|
| **Resource Optimization** | ~1.6 GB vs ~3+ GB<br>• Disabled: Realtime, Analytics, Edge Functions, Vector logging<br>• Ideal for development and small-scale deployments<br>• See [OPTIMIZATION.md](./OPTIMIZATION.md) for details |
| **Custom PostgreSQL Port** | 54322 instead of 5432<br>• Avoids conflicts with existing PostgreSQL installations<br>• Internal: 5432, External: 54322 |
| **Automated Setup** | Single command setup with validation<br>• Auto-downloads missing initialization files<br>• Configured for immediate use |
| **DigitalOcean Benchmarking** | Resource limit testing for different droplet sizes<br>• See [DIGITALOCEAN-BENCHMARKS.md](./DIGITALOCEAN-BENCHMARKS.md) |
| **Enhanced Documentation** | Comprehensive workflows and troubleshooting<br>• Development-focused quick reference |

### When to Use

| Use This Fork | Use Official Supabase |
|---------------|----------------------|
| Production deployments on resource-constrained servers (VPS, small droplets) | Need Realtime subscriptions or Edge Functions |
| Local development environments | Require full feature set including analytics |
| Self-hosted setups where Realtime/Edge Functions aren't needed | Enterprise-scale deployments |
| Learning Supabase internals | |
| Cost-effective production hosting | |

---

## Prerequisites

- Docker & Docker Compose
- 8GB+ RAM recommended (optimized stack uses ~1.6 GB)

---

## Quick Start

```bash
# Clone the repository (SSH)
git clone git@github.com:KahitSan/supabase-air.git
cd supabase-air

# Start Supabase (handles setup automatically)
./start.sh

# Or start with specific resource limits
./start.sh 4gb              # 4GB plan
./start.sh unlimited        # No limits (default)

# Reset environment only (stops services, deletes all data)
./start.sh --reset
```

The `start.sh` script will automatically:
- Detect if first-time setup is needed
- Configure environment and download required files
- Start services with optional resource limits
- Show interactive plan selection if no plan specified

Access dashboard: **http://localhost:8000**

**Alternative: Manual setup**
```bash
# If you prefer manual control
cp docker/.env.example docker/.env
./setup.sh
```

---

## Common Commands

### Quick Start (Recommended)

| Command | Description |
|---------|-------------|
| `./start.sh` | Start with interactive plan selection |
| `./start.sh 4gb` | Start with specific plan (recommended for production testing) |
| `./start.sh unlimited` | Start without limits (development) |
| `./start.sh --reset` | Reset environment only (stops services, deletes all data) |
| `./start.sh --help` | Show help |
| `cd docker && ./do-limits.sh stats` | View resource usage |
| `cd docker && docker compose logs -f` | View logs |
| `cd docker && ./do-limits.sh stop` | Stop services |

### Advanced: Direct Commands

> **Note**: Most users should use `./start.sh` instead. These commands are for advanced use cases.

| Command | Description |
|---------|-------------|
| `./setup.sh` | Start without resource limits |
| `./setup.sh --reset` | Reset everything (deletes all data) |
| `cd docker && docker compose logs -f db` | View specific service logs |
| `cd docker && docker compose ps` | Check service status |
| `cd docker && docker compose restart db` | Restart specific service |
| `cd docker && docker compose down` | Stop services |

### Advanced: Resource Limits

> **Note**: Run these commands from the `docker/` directory

| Command | Description |
|---------|-------------|
| `./do-limits.sh start 4gb` | Start with 4GB / 2 CPU plan ($24/mo) |
| `./do-limits.sh start 2gb` | Start with 2GB / 1 CPU plan ($12/mo) |
| `./do-limits.sh start unlimited` | Start without limits (default) |
| `./do-limits.sh stats` | Check resource usage |
| `./do-limits.sh stop` | Stop services |

**Available Plans:**

| Plan | Price | CPU | RAM | Use Case |
|------|-------|-----|-----|----------|
| `512mb` | $4/mo | 1 CPU | 512MB | Not viable |
| `1gb` | $6/mo | 1 CPU | 1GB | Dev/test only |
| `2gb` | $12/mo | 1 CPU | 2GB | Minimum production |
| `2gb-2cpu` | $18/mo | 2 CPUs | 2GB | Better performance |
| `4gb` ⭐ | $24/mo | 2 CPUs | 4GB | Recommended |
| `8gb` | $48/mo | 4 CPUs | 8GB | High traffic |
| `16gb` | $96/mo | 8 CPUs | 16GB | Enterprise |
| `unlimited` | - | No limit | No limit | Development |

See [DIGITALOCEAN-BENCHMARKS.md](./DIGITALOCEAN-BENCHMARKS.md) for all available plans.

---

## Service Architecture

### Access Points

| Service | URL/Port |
|---------|----------|
| Dashboard | http://localhost:8000 |
| API | http://localhost:8000 |
| Database | localhost:54322 |

Credentials are in `docker/.env`

### Active Containers (Optimized Setup)

**Running Services (9 containers):**

| Container | Purpose | Internal Port | External Port | Memory |
|-----------|---------|---------------|---------------|--------|
| `supabase-kong` | API gateway | 8000 | 8000 | ~942 MB |
| `supabase-pooler` | Connection pooler | - | 6543 | ~178 MB |
| `supabase-studio` | Web dashboard | 3000 | 8000 | ~145 MB |
| `supabase-storage` | File storage | 5000 | - | ~103 MB |
| `supabase-db` | PostgreSQL database | 5432 | 54322 | ~102 MB |
| `supabase-meta` | Database metadata | 8080 | - | ~78 MB |
| `supabase-imgproxy` | Image optimization | 5001 | - | ~25 MB |
| `supabase-auth` | GoTrue auth server | 9999 | - | ~23 MB |
| `supabase-rest` | PostgREST API | 3000 | - | ~13 MB |

**Total: ~1.6 GB RAM usage**

**Disabled Services** (not running, see [OPTIMIZATION.md](./OPTIMIZATION.md) to re-enable):
- `realtime` - WebSocket realtime subscriptions
- `analytics` - Logflare logging and monitoring
- `functions` - Edge functions runtime
- `vector` - Log aggregation

### Network Flow

```
Host Machine (localhost)
│
├─ Port 8000 ────────► Kong (API Gateway)
│                       └─► Routes to: Auth, REST, Storage, Studio
│
├─ Port 54322 ──────► PostgreSQL (supabase-db:5432)
│
Docker Network (172.x.x.x)
└─ All services connect internally using service names
   (e.g., db:5432, auth:9999, rest:3000)
```

---

## Backup & Restore

### Database Backup

```bash
cd docker
PGPASSWORD=$(grep POSTGRES_PASSWORD .env | cut -d'=' -f2) \
  pg_dump -h localhost -p 54322 -U postgres -d postgres > backup_$(date +%Y%m%d_%H%M%S).sql
```

### Volumes Backup

```bash
cd docker
tar czf volumes_backup_$(date +%Y%m%d_%H%M%S).tar.gz volumes/
```

### Database Restore

```bash
# Reset environment
./start.sh --reset

# Start services
./start.sh

# Restore from backup
cd docker
PGPASSWORD=$(grep POSTGRES_PASSWORD .env | cut -d'=' -f2) \
  psql -h localhost -p 54322 -U postgres -d postgres < backup_20251102_120000.sql
```

### Volumes Restore

```bash
cd docker && docker compose down
tar xzf volumes_backup_20251102_120000.tar.gz
./start.sh
```

---

## Troubleshooting

### Service Management Commands

| Command | Description |
|---------|-------------|
| `cd docker && docker compose ps` | Check service status |
| `cd docker && docker compose logs -f [service-name]` | View service logs (all services or specific) |
| `cd docker && docker compose restart [service-name]` | Restart service |
| `cd docker && docker compose up -d --force-recreate [service-name]` | Rebuild service |

### Common Issues

**Services Not Starting**

```bash
# Check container status
cd docker && docker compose ps

# View error logs
cd docker && docker compose logs -f

# Full reset and restart
./start.sh --reset
./start.sh
```

**Database Connection Refused**

Check if Supabase is running:
```bash
cd docker && docker compose ps
```

Check port mapping:
```bash
docker ps | grep 54322
```

Verify PostgreSQL port:
```bash
docker exec supabase-db psql -U postgres -c "SHOW port;"
```

Verify configuration:
```bash
cd docker
grep "POSTGRES_PORT=" .env          # Should be 5432
grep "POSTGRES_EXTERNAL_PORT=" .env # Should be 54322
```

If wrong, fix and restart:
```bash
./start.sh --reset
./start.sh
```

**Port Already in Use**

Find process using port:
```bash
sudo lsof -i :54322
sudo lsof -i :8000
```

Kill process if needed:
```bash
sudo kill -9 <PID>
```

---

## Configuration

**Key Settings:**
- `POSTGRES_PORT=5432` - Internal Docker network port (do not change)
- `POSTGRES_EXTERNAL_PORT=54322` - Host machine access port (customizable)

See `docker/.env` for all configuration.

### Updating Configuration

| Step | Command | Description |
|------|---------|-------------|
| 1 | `cd docker && docker compose down` | Stop services |
| 2 | `vim docker/.env` | Edit .env file |
| 3 | `./start.sh` | Restart services |

---

## Pro Tips

| Tip | Details |
|-----|---------|
| **Always use `./start.sh`** | Simplest way to start services with automatic setup detection |
| **Never commit `docker/.env`** | Contains secrets |
| **Use `--reset` flag liberally** | During development - `./start.sh --reset` then `./start.sh` for fresh start |
| **Check logs first** | When troubleshooting: `cd docker && docker compose logs -f` |
| **Database port is 54322 externally, 5432 internally** | This is intentional to avoid conflicts |
| **Interactive menu** | Run `./start.sh` without arguments to choose resource plan interactively |

---

## Documentation

- **[OPTIMIZATION.md](./OPTIMIZATION.md)** - Resource usage metrics and disabled services
- **[DIGITALOCEAN-BENCHMARKS.md](./DIGITALOCEAN-BENCHMARKS.md)** - Deployment sizing and resource limits
- **[Official Supabase Docs](https://supabase.com/docs/guides/self-hosting)** - Self-hosting guide

---

## Repository Structure

```
supabase-air/
├── start.sh                # Unified startup script (recommended)
├── setup.sh                # Automated setup script
├── docker/
│   ├── .env                # Configuration (gitignored)
│   ├── docker-compose.yml  # Service definitions
│   ├── do-limits.sh        # Resource limiting helper
│   ├── dev-utils.sh        # Development utilities
│   └── volumes/            # Persistent data (gitignored)
├── OPTIMIZATION.md         # Resource usage & optimization guide
├── DIGITALOCEAN-BENCHMARKS.md  # Deployment benchmarks
└── README.md               # This file
```

---

## Service Versions

| Service | Version |
|---------|---------|
| **Supabase Studio** | 2025.06.30-sha-6f5982d |
| **PostgreSQL** | 15.8.1.060 |
| **GoTrue (Auth)** | v2.177.0 |
| **PostgREST** | v12.2.12 |
| **Storage API** | v1.25.7 |
| **Postgres Meta** | v0.91.0 |
| **Supavisor (Pooler)** | 2.5.7 |

*Disabled services (can be re-enabled):*
- Realtime: v2.34.47
- Edge Runtime: v1.67.4
- Logflare: 1.14.2

---

**Status**: ✅ Production Ready | **Last Updated**: December 24, 2025

---

## Credits & License

This repository is a customized fork based on [supabase/supabase](https://github.com/supabase/supabase).

### Original Project
- **Repository**: [supabase/supabase](https://github.com/supabase/supabase)
- **License**: Apache License 2.0
- **Credits**: All core Supabase functionality is developed and maintained by the Supabase team

### This Fork
- **Maintained by**: [@KahitSan](https://github.com/KahitSan)
- **Purpose**: Production-ready, optimized self-hosting setup for resource-constrained environments
- **Use Cases**: Development, production VPS hosting, cost-effective deployments
- **Changes**: See [What's Different](#whats-different-from-official-supabase) section above

**Note**: This is not an official Supabase project. For official self-hosting documentation, visit [supabase.com/docs/guides/self-hosting](https://supabase.com/docs/guides/self-hosting).
