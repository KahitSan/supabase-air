# Developer Workflows

Common workflows for working with this Supabase infrastructure.

---

## Daily Operations

```bash
# Start Supabase
./setup.sh

# Stop services
cd docker && docker compose down

# View logs
cd docker && docker compose logs -f

# View specific service logs
cd docker && docker compose logs -f db

# Check service status
cd docker && docker compose ps

# Restart specific service
cd docker && docker compose restart db
```

---

## Fresh Environment Setup

```bash
# Clean slate
./setup.sh --reset
```

**Note**: This deletes all data. Use with caution.

---

## Updating Configuration

```bash
# 1. Stop services
cd docker && docker compose down

# 2. Edit .env
vim docker/.env

# 3. Restart
./setup.sh
```

---

## Backing Up Data

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

---

## Restoring Data

### Database Restore

```bash
# Start fresh
./setup.sh --reset

# Restore from backup
cd docker
PGPASSWORD=$(grep POSTGRES_PASSWORD .env | cut -d'=' -f2) \
  psql -h localhost -p 54322 -U postgres -d postgres < backup_20251102_120000.sql
```

### Volumes Restore

```bash
cd docker && docker compose down
tar xzf volumes_backup_20251102_120000.tar.gz
./setup.sh
```

---

## Troubleshooting Services

### Check Service Status

```bash
cd docker && docker compose ps
```

### View Service Logs

```bash
cd docker && docker compose logs -f [service-name]
```

### Restart Service

```bash
cd docker && docker compose restart [service-name]
```

### Rebuild Service

```bash
cd docker && docker compose up -d --force-recreate [service-name]
```

---

## Common Issues

### Services Not Starting

```bash
# Check container status
cd docker && docker compose ps

# View error logs
cd docker && docker compose logs -f

# Full reset
./setup.sh --reset
```

### Database Connection Refused

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
./setup.sh --reset
```

### Port Already in Use

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

## Service Architecture

### Access Points

| Service | URL/Port |
|---------|----------|
| Dashboard | http://localhost:8000 |
| API | http://localhost:8000 |
| Database | localhost:54322 |

Credentials are in `docker/.env`

### Container Ports

| Container | Internal Port | External Port |
|-----------|---------------|---------------|
| supabase-db | 5432 | 54322 |
| supabase-auth | 9999 | - |
| supabase-rest | 3000 | - |
| supabase-storage | 5000 | - |
| supabase-meta | 8080 | - |
| supabase-studio | 3000 | 8000 |
| kong | 8000 | 8000 |
| imgproxy | 5001 | - |

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

### Key Configuration

- `POSTGRES_PORT=5432` - Internal Docker network port (do not change)
- `POSTGRES_EXTERNAL_PORT=54322` - Host machine access port (customizable)

---

## Pro Tips

1. **Always use `./setup.sh`** instead of manually running `docker compose up`
2. **Never commit `docker/.env`** - contains secrets
3. **Use `--reset` flag liberally** during development - fresh start fixes most issues
4. **Check logs first** when troubleshooting: `cd docker && docker compose logs -f`
5. **Database port is 54322 externally, 5432 internally** - this is intentional
6. **Keep `setup.sh` idempotent** - should be safe to run multiple times
