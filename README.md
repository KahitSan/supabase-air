# Supabase Self-Hosted Infrastructure

Docker Compose infrastructure for running Supabase locally.

---

## Quick Start

```bash
./setup.sh
```

Access dashboard: **http://localhost:8000**

---

## Common Commands

```bash
# Start Supabase
./setup.sh

# Reset everything (⚠️ deletes all data)
./setup.sh --reset

# View logs
cd docker && docker compose logs -f

# Stop services
cd docker && docker compose down
```

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

- **[OPTIMIZATION.md](./OPTIMIZATION.md)** - Resource usage metrics and how to re-enable services
- **[CLAUDE.md](./CLAUDE.md)** - Quick reference for development with Claude Code
- **[setup.sh](./setup.sh)** - Automated setup script with validation
- **[Official Supabase Docs](https://supabase.com/docs/guides/self-hosting)** - Self-hosting guide

---

## Repository Structure

```
supabase-dev/
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
