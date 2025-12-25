# Docker Directory

Docker Compose configuration for Supabase services.

> **Note**: For general setup and usage instructions, see the [main README](../README.md). This file only documents docker-specific configuration.
>
> **Utility scripts** have been moved to `../scripts/` directory for better organization.

---

## Directory Structure

```
docker/
├── .env                       # Environment configuration (gitignored)
├── .env.example               # Environment template
├── docker-compose.yml         # Main service definitions
├── docker-compose.do-*.yml    # Resource limit configs (8 files)
└── volumes/                   # Persistent data (gitignored)
    ├── db/                    # PostgreSQL data and initialization
    ├── storage/               # File storage
    ├── api/                   # Kong configuration
    ├── logs/                  # Vector logging config
    └── pooler/                # Supavisor config
```

---

## Utility Scripts

> **Note**: All utility scripts are located in `../scripts/` directory. Run them from the project root.

### do-limits.sh

Resource limiting and DigitalOcean plan simulation.

| Command | Description |
|---------|-------------|
| `./scripts/do-limits.sh start <plan>` | Start with specific resource limits |
| `./scripts/do-limits.sh setup` | Start without limits (alias for `start unlimited`) |
| `./scripts/do-limits.sh stop` | Stop all services |
| `./scripts/do-limits.sh stats` | Show resource usage |
| `./scripts/do-limits.sh test <plan>` | Run benchmark on specific plan |
| `./scripts/do-limits.sh test-all` | Benchmark all plans |
| `./scripts/do-limits.sh list` | List available plans |

**Available plans**: `512mb`, `1gb`, `2gb`, `2gb-2cpu`, `4gb`, `8gb`, `16gb`, `unlimited`

### dev-utils.sh

Development and maintenance utilities.

| Command | Description |
|---------|-------------|
| `./scripts/dev-utils.sh status` | Show service health |
| `./scripts/dev-utils.sh logs [service]` | Stream logs (all or specific) |
| `./scripts/dev-utils.sh restart [service]` | Restart services |
| `./scripts/dev-utils.sh shell` | Open bash in database container |
| `./scripts/dev-utils.sh psql` | Connect to PostgreSQL |
| `./scripts/dev-utils.sh backup` | Create database backup |
| `./scripts/dev-utils.sh restore` | Restore from backup |
| `./scripts/dev-utils.sh update` | Pull latest images and restart |
| `./scripts/dev-utils.sh clean` | Clean up Docker resources |
| `./scripts/dev-utils.sh env` | Show environment configuration |

### show-status.sh

Displays comprehensive system information including service versions, health status, URLs, credentials, and configuration.

```bash
./scripts/show-status.sh
```

### load-test.sh

Performance testing script used by `do-limits.sh` for benchmarking database operations under different resource constraints.

---

## Configuration Files

### .env

Environment variables for all services. Copy from `.env.example` to get started.

**Key variables:**

| Variable | Description | Default |
|----------|-------------|---------|
| `POSTGRES_PASSWORD` | Database password | (required) |
| `POSTGRES_PORT` | Internal Docker port | `5432` |
| `POSTGRES_EXTERNAL_PORT` | Host machine port | `54322` |
| `JWT_SECRET` | JWT signing secret | (required) |
| `ANON_KEY` | Anonymous API key | (auto-generated) |
| `SERVICE_ROLE_KEY` | Service role API key | (auto-generated) |
| `DASHBOARD_USERNAME` | Dashboard login | `kahitsan` |
| `DASHBOARD_PASSWORD` | Dashboard password | (required) |

### docker-compose.yml

Main service definitions for 9 active containers:
- `kong` - API gateway
- `db` - PostgreSQL database
- `auth` - GoTrue authentication
- `rest` - PostgREST API
- `storage` - File storage
- `meta` - Database metadata
- `studio` - Web dashboard
- `pooler` - Supavisor connection pooler
- `imgproxy` - Image optimization

**Disabled services** (can be re-enabled in OPTIMIZATION.md):
- `realtime` - WebSocket subscriptions
- `analytics` - Logflare logging
- `functions` - Edge functions runtime
- `vector` - Log aggregation

### docker-compose.do-*.yml

Resource limit override files for DigitalOcean plan simulation:
- `docker-compose.do-512mb.yml`
- `docker-compose.do-1gb.yml`
- `docker-compose.do-2gb.yml`
- `docker-compose.do-2gb-2cpu.yml`
- `docker-compose.do-4gb.yml`
- `docker-compose.do-8gb.yml`
- `docker-compose.do-16gb.yml`

Used by `do-limits.sh` to apply memory and CPU constraints.

---

## Port Mappings

| Internal Port | External Port | Service | Description |
|---------------|---------------|---------|-------------|
| 8000 | 8000 | Kong | API Gateway + Dashboard |
| 8443 | 8443 | Kong | HTTPS Gateway |
| 5432 | 54322 | PostgreSQL | Database |
| 6543 | 6543 | Supavisor | Connection pooler |
| 3000 | - | Studio | Dashboard (via Kong) |
| 3000 | - | PostgREST | API (via Kong) |
| 9999 | - | GoTrue | Auth (via Kong) |
| 5000 | - | Storage | File storage (via Kong) |

**Note**: Most services are accessed through Kong (port 8000), not directly.

---

## Direct Docker Compose Commands

For advanced users who want direct control:

```bash
# Start services
docker compose up -d

# Stop services
docker compose down

# View logs
docker compose logs -f [service_name]

# Check status
docker compose ps

# Restart service
docker compose restart [service_name]

# Rebuild service
docker compose up -d --force-recreate [service_name]
```

---

For general usage, troubleshooting, and setup instructions, see the [main README](../README.md).
