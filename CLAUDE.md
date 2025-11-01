# Claude Code Quick Reference - Supabase Dev

**READ THIS FIRST** in every new session to avoid re-analyzing the entire codebase.

---
**Last updated**: 2025-11-02
---

## 🎯 Quick Navigation

| Task | Go To |
|------|-------|
| Understanding project structure | [Project Structure](#-project-structure) below |
| Running Supabase locally | [Running Supabase](#-running-supabase) below |
| Troubleshooting | [Common Issues](#-common-issues--solutions) below |
| Creating commits | [Git Workflow](#-git-workflow) below |
| Creating PRs | [Git Workflow](#-git-workflow) below |

---

## 📋 User Preferences & Rules

### Commit Messages
- ✅ **Keep brief and short** - no long explanations
- ✅ Analyze `git diff` before suggesting message
- ✅ Format: `type: brief description` (e.g., `fix: correct postgres port mapping`)
- ❌ Do NOT write lengthy commit messages
- ❌ Do not write: 🤖 Generated with Claude Code or Co-Authored By Claude

### Pull Request Titles & Descriptions

**Titles:**
- ❌ Do NOT use commit prefixes (feat:, fix:, docs:, etc.) in PR titles
- ✅ Use plain descriptive titles (e.g., "Add backup script" not "feat: add backup script")
- ✅ PR titles are for humans, commit messages are for history

**Descriptions:**
- ✅ **Write casually** like a developer, not formally
- ✅ Brief narrative of what changed
- ✅ Mention if changes differ from original plan
- ❌ **NO stats** in PR descriptions
- ❌ **NO TODO lists** in PR descriptions
- ❌ Do NOT use verbose/formal language

**Bad PR example:**
```
## Summary
Implemented backup script with comprehensive error handling.

## Stats
- Files changed: 3
- Lines added: 150

## TODO
- [ ] Add more validation
- [ ] Update docs
```

**Good PR example:**
```
Added a backup script that dumps the database and copies volumes to a timestamped
directory. Also updated the setup script to handle missing initialization files
better by downloading them automatically.
```

---

## 🏗️ Project Structure

### Directory Layout
```
supabase-dev/
├── setup.sh              # Main setup script - start here
├── docker/
│   ├── .env              # Configuration (NEVER commit secrets)
│   ├── .env.example      # Template for .env
│   ├── docker-compose.yml # Supabase services
│   ├── reset.sh          # Reset database script
│   ├── setup.sh          # Docker-specific setup
│   ├── show-status.sh    # Service status checker
│   └── volumes/          # Persistent data (gitignored)
│       ├── db/           # PostgreSQL data & config
│       ├── api/          # Kong API gateway config
│       ├── logs/         # Vector logging config
│       └── pooler/       # PgBouncer config
├── supabase/             # Supabase Studio files (optional)
└── README.md
```

### Key Files
- **Entry point**: `setup.sh` - automated setup with validation
- **Config**: `docker/.env` - all environment variables
- **Services**: `docker/docker-compose.yml` - service definitions
- **Scripts**: `docker/*.sh` - utility scripts

---

## 🚀 Running Supabase

### First Time Setup

```bash
# From project root
./setup.sh
```

This automatically:
- Checks prerequisites (Docker, Docker Compose)
- Validates `.env` configuration
- Downloads missing initialization files
- Creates custom PostgreSQL configuration
- Starts all services
- Verifies database connectivity

### Daily Operations

```bash
# Start Supabase
./setup.sh

# Reset everything (⚠️ DESTRUCTIVE - deletes all data)
./setup.sh --reset

# Stop services
cd docker && docker compose down

# View logs
cd docker && docker compose logs -f

# View specific service logs
cd docker && docker compose logs -f db
cd docker && docker compose logs -f auth
cd docker && docker compose logs -f rest

# Check service status
cd docker && docker compose ps

# Restart specific service
cd docker && docker compose restart db
```

### Access Information

| Service | URL/Port | Credentials |
|---------|----------|-------------|
| **Dashboard** | http://localhost:8000 | See `docker/.env` |
| **API** | http://localhost:8000 | Use ANON_KEY from `.env` |
| **Database** | localhost:54322 | postgres / (see `.env`) |

---

## 🔧 Git Workflow

### Branch Management
- **Main branch**: `master` (not `main`)
- **Always checkout from latest remote master**: `git checkout master && git pull origin master`
- Create feature branches from latest `master`
- Branch naming: `type/brief-description` (e.g., `feat/backup-script`, `fix/port-mapping`)

### Commit Message Format
1. Run `git diff` first
2. Analyze changes
3. Write brief commit message
4. Format: `type: description`
   - Types: `feat`, `fix`, `refactor`, `docs`, `ci`, `chore`

### Creating Pull Requests
1. Push branch
2. Use `gh pr create --assignee @me`
3. **Title**: Use plain English, NO commit prefixes (feat:, fix:, etc.)
4. **Description**: Write casual, brief narrative
5. **Do NOT include stats or TODO lists**
6. Mention changes from original plan if applicable

### After Pushing New Commits to PR
1. **Always review the PR description** to check if it needs updating
2. Update description if the new commit adds significant changes not mentioned
3. Skip updating if commit is just a refinement/fix of what's already described

---

## 🐛 Common Issues & Solutions

### Services Not Starting

**Issue**: Docker containers fail to start

**Solutions:**
```bash
# Check container status
cd docker && docker compose ps

# View error logs
cd docker && docker compose logs -f

# Full reset
./setup.sh --reset
```

### Database Connection Refused

**Issue**: Can't connect to database on port 54322

**Check:**
1. Is Supabase running? `cd docker && docker compose ps`
2. Is port 54322 mapped? `docker ps | grep 54322`
3. Is PostgreSQL listening on port 5432 internally?
   ```bash
   docker exec supabase-db psql -U postgres -c "SHOW port;"
   ```

**Fix:**
```bash
# Verify .env configuration
cd docker
grep "POSTGRES_PORT=" .env          # Should be 5432
grep "POSTGRES_EXTERNAL_PORT=" .env # Should be 54322

# If wrong, fix and restart
./setup.sh --reset
```

### Missing Initialization Files

**Issue**: Services fail with "file not found" errors

**Solution:**
```bash
# setup.sh automatically downloads missing files
./setup.sh

# Or manually download from Supabase repo
# (see setup.sh for download logic)
```

### Port Already in Use

**Issue**: Port 54322 or 8000 already in use

**Check:**
```bash
# Find process using port
sudo lsof -i :54322
sudo lsof -i :8000

# Kill if needed
sudo kill -9 <PID>
```

### Database Data Corruption

**Issue**: Database won't start or has corrupted data

**Solution:**
```bash
# Nuclear option - reset everything
./setup.sh --reset

# Then re-apply migrations from uni-api
cd ~/Projects/uni-api
supabase db push --db-url "postgresql://postgres:PASSWORD@localhost:54322/postgres?sslmode=disable"
```

---

## 🔍 Common Search Patterns

When I need to find:

| Looking for | Command | Pattern |
|-------------|---------|---------|
| Service definitions | `grep -A 10 "service-name:" docker/docker-compose.yml` | YAML service blocks |
| Environment variables | `grep "VARIABLE_NAME" docker/.env` | Key-value pairs |
| Port mappings | `grep "ports:" docker/docker-compose.yml` | Port configuration |
| Volume mounts | `grep "volumes:" docker/docker-compose.yml` | Volume paths |
| PostgreSQL config | `cat docker/volumes/db/pg_hba.conf` | Auth configuration |

---

## 📦 Key Services

### Container Overview

| Container | Purpose | Internal Port | External Port |
|-----------|---------|---------------|---------------|
| `supabase-db` | PostgreSQL database | 5432 | 54322 |
| `supabase-auth` | GoTrue auth server | 9999 | - |
| `supabase-rest` | PostgREST API | 3000 | - |
| `supabase-realtime` | Realtime subscriptions | 4000 | - |
| `supabase-storage` | File storage | 5000 | - |
| `supabase-meta` | Database metadata | 8080 | - |
| `supabase-studio` | Web dashboard | 3000 | 8000 |
| `kong` | API gateway | 8000 | 8000 |
| `vector` | Log aggregation | - | - |
| `imgproxy` | Image optimization | 5001 | - |

### Architecture

```
Host Machine (localhost)
│
├─ Port 8000 ────────► Kong (API Gateway)
│                       └─► Routes to: Auth, REST, Storage, Realtime, Studio
│
├─ Port 54322 ──────► PostgreSQL (supabase-db:5432)
│
Docker Network (172.x.x.x)
└─ All services connect internally using service names
   (e.g., db:5432, auth:9999, rest:3000)
```

**Key Configuration:**
- `POSTGRES_PORT=5432` - Internal Docker network port
- `POSTGRES_EXTERNAL_PORT=54322` - Host machine access port

---

## 💡 Pro Tips

1. **Always use `./setup.sh`** instead of manually running `docker compose up`
2. **Never commit `docker/.env`** - contains secrets
3. **Use `--reset` flag liberally** during development - fresh start fixes most issues
4. **Check logs first** when troubleshooting: `cd docker && docker compose logs -f`
5. **Database port is 54322 externally, 5432 internally** - this is intentional
6. **This repo is infrastructure only** - migrations live in `uni-api` repo
7. **Keep `setup.sh` idempotent** - should be safe to run multiple times

---

## 🚀 Typical Workflows

### Starting Fresh Environment

```bash
# Clean slate
./setup.sh --reset

# Apply all migrations from uni-api
cd ~/Projects/uni-api
export DB_PASSWORD="your-password"
supabase db push --db-url "postgresql://postgres:${DB_PASSWORD}@localhost:54322/postgres?sslmode=disable"
```

### Updating Configuration

```bash
# 1. Stop services
cd docker && docker compose down

# 2. Edit .env
vim docker/.env

# 3. Restart
./setup.sh
```

### Backing Up Data

```bash
# Backup database
cd docker
PGPASSWORD=$(grep POSTGRES_PASSWORD .env | cut -d'=' -f2) \
  pg_dump -h localhost -p 54322 -U postgres -d postgres > backup_$(date +%Y%m%d_%H%M%S).sql

# Backup volumes
cd docker
tar czf volumes_backup_$(date +%Y%m%d_%H%M%S).tar.gz volumes/
```

### Restoring Data

```bash
# Restore database
./setup.sh --reset  # Start fresh

cd docker
PGPASSWORD=$(grep POSTGRES_PASSWORD .env | cut -d'=' -f2) \
  psql -h localhost -p 54322 -U postgres -d postgres < backup_20251102_120000.sql

# Restore volumes
cd docker && docker compose down
tar xzf volumes_backup_20251102_120000.tar.gz
./setup.sh
```

### Troubleshooting a Service

```bash
# Check service status
cd docker && docker compose ps

# View service logs
cd docker && docker compose logs -f [service-name]

# Restart specific service
cd docker && docker compose restart [service-name]

# Rebuild and restart
cd docker && docker compose up -d --force-recreate [service-name]
```

---

## 📖 Related Documentation

This repository is **infrastructure only**. For application-level documentation:

- **[uni-api/SUPABASE_WORKFLOW.md](../uni-api/SUPABASE_WORKFLOW.md)** - Main workflow guide for migrations
- **[uni-api/SUPABASE_LOCAL_SETUP.md](../uni-api/SUPABASE_LOCAL_SETUP.md)** - Detailed setup with examples
- **[Official Supabase Docs](https://supabase.com/docs/guides/self-hosting)** - Self-hosting guide

---

## 🎯 Project Purpose

This repository provides:
- ✅ Self-hosted Supabase infrastructure
- ✅ Docker Compose configuration
- ✅ Automated setup scripts
- ✅ Service orchestration

This repository does NOT contain:
- ❌ Application code
- ❌ Database migrations
- ❌ Business logic

For application code and migrations, see: **[uni-api](../uni-api/)**

---

## ⚙️ Configuration Reference

### Critical Environment Variables

From `docker/.env`:

```bash
# PostgreSQL Configuration
POSTGRES_PORT=5432              # Internal (DO NOT CHANGE)
POSTGRES_EXTERNAL_PORT=54322    # External (customize if needed)
POSTGRES_PASSWORD=your-password # Database password

# Dashboard Access
DASHBOARD_USERNAME=kahitsan
DASHBOARD_PASSWORD=your-password

# JWT Secret
JWT_SECRET=your-jwt-secret

# Anon/Service Keys
ANON_KEY=your-anon-key
SERVICE_ROLE_KEY=your-service-role-key
```

### File Permissions

Some operations require sudo:
- Creating/modifying `volumes/` directory
- Resetting database data

The `setup.sh` script handles this automatically.

---
