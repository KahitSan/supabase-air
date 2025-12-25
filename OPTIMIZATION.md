# Supabase Optimization Branch

This branch contains an optimized Supabase configuration that disables unused services to reduce resource consumption and improve performance.

## Overview

This optimized configuration disables unused services to reduce resource consumption. See [README.md](./README.md) Service Architecture section for the complete list of active and disabled services.

**Resource Savings:** ~450-700 MB compared to full stack (total usage ~1.6 GB vs ~2.1-2.3 GB)

## How to Re-enable Services

All disabled services are commented out with clear markers. To re-enable any service:

### Re-enabling Docker Services

1. Open `docker/docker-compose.yml`
2. Find the service marked with `# OPTIMIZATION:` comment
3. Uncomment the entire service block
4. Find dependencies on that service in other services (also marked with `# OPTIMIZATION:`)
5. Uncomment those dependencies
6. Restart the stack: `docker compose down && docker compose up -d`

**Example - Re-enabling Realtime:**

```yaml
# Find and uncomment in docker-compose.yml:
realtime:
  container_name: realtime-dev.supabase-realtime
  image: supabase/realtime:v2.34.47
  # ... rest of config

# Also uncomment in other services that depend on it:
depends_on:
  analytics:  # If re-enabling analytics too
    condition: service_healthy
```

### Re-enabling Analytics

Analytics requires multiple changes:

1. **docker-compose.yml** - Uncomment:
   - `analytics` service
   - `vector` service
   - All `depends_on: analytics` sections in other services
   - Analytics environment variables in `studio` service

2. **Restart services:**
   ```bash
   docker compose down
   docker compose up -d
   ```

### Re-enabling API Routes

1. Open `docker/volumes/api/kong.yml`
2. Find the route marked with `# OPTIMIZATION:` comment
3. Uncomment the route configuration
4. Restart Kong: `docker compose restart kong`

**Example - Re-enabling GraphQL:**

```yaml
# Uncomment in kong.yml:
- name: graphql-v1
  _comment: 'PostgREST: /graphql/v1/* -> http://rest:3000/rpc/graphql'
  url: http://rest:3000/rpc/graphql
  routes:
    - name: graphql-v1-all
      strip_path: true
      paths:
        - /graphql/v1
  plugins:
    # ... rest of config
```

### Re-enabling Edge Functions

1. **docker-compose.yml** - Uncomment the `functions` service
2. **kong.yml** - Uncomment the `functions-v1` route
3. Restart: `docker compose down && docker compose up -d`

## Quick Reference

| Service/Route | File | Line Markers |
|--------------|------|--------------|
| Realtime Service | docker/docker-compose.yml | `# OPTIMIZATION: Realtime disabled` |
| Analytics Service | docker/docker-compose.yml | `# OPTIMIZATION: Analytics/Logflare disabled` |
| Vector Service | docker/docker-compose.yml | `# OPTIMIZATION: Vector logging disabled` |
| Functions Service | docker/docker-compose.yml | `# OPTIMIZATION: Edge Functions disabled` |
| GraphQL Route | docker/volumes/api/kong.yml | `# OPTIMIZATION: GraphQL routes disabled` |
| Realtime Routes | docker/volumes/api/kong.yml | `# OPTIMIZATION: Realtime routes disabled` |
| Functions Route | docker/volumes/api/kong.yml | `# OPTIMIZATION: Edge Functions routes disabled` |
| Analytics Route | docker/volumes/api/kong.yml | `# OPTIMIZATION: Analytics routes disabled` |

## Use Cases

This optimized configuration is ideal for:

- Development environments focused on API and Storage only
- Production deployments that don't require realtime features
- Resource-constrained environments
- Projects using external analytics/logging solutions
- Serverless architectures with external function hosting

## Testing After Re-enabling

After re-enabling services, verify they work:

```bash
# Check all services are healthy
./supabase.sh container-status

# Or use direct docker command
cd docker && docker compose ps

# Test specific endpoints (get your keys with: ./supabase.sh status)
# Realtime
curl -X GET 'http://localhost:8000/realtime/v1/api/tenants'

# GraphQL
curl -X POST 'http://localhost:8000/graphql/v1' \
  -H 'apikey: YOUR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{"query": "{ __typename }"}'

# Functions (if you have functions deployed)
curl -X POST 'http://localhost:8000/functions/v1/YOUR_FUNCTION' \
  -H 'apikey: YOUR_ANON_KEY'
```

## Notes

- All optimization comments are prefixed with `# OPTIMIZATION:` for easy searching
- Service dependencies have also been updated (marked with comments)
- The backup of the original kong.yml is saved as `kong.yml.bak` in `docker/volumes/api/`
- No data is lost - re-enabling services will restore full functionality
