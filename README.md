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

---

## Configuration

**Key Settings:**
- `POSTGRES_PORT=5432` - Internal Docker network port
- `POSTGRES_EXTERNAL_PORT=54322` - Host machine access port

See `docker/.env` for all configuration.

---

## Documentation

This repository provides **infrastructure only**. For complete documentation on using Supabase with your application:

**📖 See: [uni-api/SUPABASE_WORKFLOW.md](../uni-api/SUPABASE_WORKFLOW.md)**

Topics covered:
- Creating and applying migrations
- Multi-environment workflow (local, test, prod)
- Database access and management
- Troubleshooting guide

**📖 Detailed Setup Guide: [uni-api/SUPABASE_LOCAL_SETUP.md](../uni-api/SUPABASE_LOCAL_SETUP.md)**

---

## Repository Structure

```
supabase-dev/          # THIS REPO - Infrastructure only
├── setup.sh           # Automated setup script
├── docker/
│   ├── .env           # Configuration
│   └── docker-compose.yml
└── README.md

uni-api/               # Application repository
├── SUPABASE_WORKFLOW.md        # Main workflow guide
├── SUPABASE_LOCAL_SETUP.md     # Detailed setup guide
└── supabase/
    └── migrations/    # Your database migrations
```

---

## Prerequisites

- Docker & Docker Compose
- Supabase CLI: `npm install -g supabase`

---

## Support

- 📖 [Workflow Guide](../uni-api/SUPABASE_WORKFLOW.md)
- 📖 [Setup Guide](../uni-api/SUPABASE_LOCAL_SETUP.md)
- 🔧 [Supabase Docs](https://supabase.com/docs)

---

**Status**: ✅ Production Ready | **Last Updated**: November 2, 2025
