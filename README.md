# Supabase Self-Hosted Infrastructure

Optimized Docker Compose setup for self-hosting Supabase with reduced resource usage. Suitable for both production and development environments.

> **Based on**: [supabase/supabase](https://github.com/supabase/supabase) - The official Supabase repository
> **Supabase Version**: Studio 2025.06.30 | PostgreSQL 15.8.1.060

---

## What's Different from Official Supabase?

This repository is an **optimized fork** of the official Supabase self-hosting setup with the following customizations:

### 🎯 Key Changes

1. **Resource Optimization** (~1.6 GB vs ~3+ GB)
   - Disabled: Realtime, Analytics, Edge Functions, Vector logging
   - Ideal for development and small-scale deployments
   - See [OPTIMIZATION.md](./OPTIMIZATION.md) for details

2. **Custom PostgreSQL Port** (54322 instead of 5432)
   - Avoids conflicts with existing PostgreSQL installations
   - Internal: 5432, External: 54322

3. **Automated Setup**
   - Single command setup with validation
   - Auto-downloads missing initialization files
   - Configured for immediate use

4. **DigitalOcean Benchmarking**
   - Resource limit testing for different droplet sizes
   - See [DIGITALOCEAN-BENCHMARKS.md](./DIGITALOCEAN-BENCHMARKS.md)

5. **Enhanced Documentation**
   - Comprehensive workflows and troubleshooting
   - Claude Code integration guide
   - Development-focused quick reference

**When to use this fork:**
- Production deployments on resource-constrained servers (VPS, small droplets)
- Local development environments
- Self-hosted setups where Realtime/Edge Functions aren't needed
- Learning Supabase internals
- Cost-effective production hosting

**When to use official Supabase:**
- Need Realtime subscriptions or Edge Functions
- Require full feature set including analytics
- Enterprise-scale deployments

---

## Quick Start

```bash
./setup.sh
```

Access dashboard: **http://localhost:8000**

---

## Common Commands

### Standard Startup (No Limits)

```bash
# Start Supabase without resource limits
./setup.sh

# Reset everything (⚠️ deletes all data)
./setup.sh --reset

# View logs
cd docker && docker compose logs -f

# Stop services
cd docker && docker compose down
```

### Startup with Resource Limits (DigitalOcean Simulation)

```bash
cd docker

# Start with specific DigitalOcean plan limits
./do-limits.sh start 4gb          # 4GB / 2 CPU plan ($24/mo)
./do-limits.sh start 2gb          # 2GB / 1 CPU plan ($12/mo)
./do-limits.sh start unlimited    # No limits (default)

# Check resource usage
./do-limits.sh stats

# Stop services
./do-limits.sh stop
```

See [DIGITALOCEAN-BENCHMARKS.md](./DIGITALOCEAN-BENCHMARKS.md) for all available plans.

---

## What This Provides

| Service | URL/Port |
|---------|----------|
| Dashboard | http://localhost:8000 |
| API | http://localhost:8000 |
| Database | localhost:54322 |

Credentials are in `docker/.env`

**⚡ Optimized Setup**: By default, realtime, analytics, edge functions, and vector logging are disabled to reduce resource usage (~1.6 GB total). See [OPTIMIZATION.md](./OPTIMIZATION.md) to re-enable these services if needed.

---

## Configuration

**Key Settings:**
- `POSTGRES_PORT=5432` - Internal Docker network port
- `POSTGRES_EXTERNAL_PORT=54322` - Host machine access port

See `docker/.env` for all configuration.

---

## Documentation

- **[WORKFLOWS.md](./WORKFLOWS.md)** - Daily operations, backups, and troubleshooting
- **[OPTIMIZATION.md](./OPTIMIZATION.md)** - Resource usage metrics and disabled services
- **[DIGITALOCEAN-BENCHMARKS.md](./DIGITALOCEAN-BENCHMARKS.md)** - Deployment sizing and resource limits
- **[CLAUDE.md](./CLAUDE.md)** - Quick reference for development with Claude Code
- **[Official Supabase Docs](https://supabase.com/docs/guides/self-hosting)** - Self-hosting guide

---

## Repository Structure

```
supabase-air/
├── setup.sh                # Automated setup script
├── docker/
│   ├── .env                # Configuration (gitignored)
│   ├── docker-compose.yml  # Service definitions
│   └── volumes/            # Persistent data (gitignored)
├── OPTIMIZATION.md         # Resource usage & optimization guide
├── CLAUDE.md               # Development quick reference
└── README.md
```

---

## Prerequisites

- Docker & Docker Compose
- 8GB+ RAM recommended (optimized stack uses ~1.6 GB)

---

**Status**: ✅ Production Ready | **Last Updated**: November 2, 2025

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
