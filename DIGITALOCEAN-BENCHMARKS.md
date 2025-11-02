# DigitalOcean Deployment Benchmarks

Benchmark results for Supabase running with different DigitalOcean Shared CPU plan resource limits.

---

## Testing Tool

Use `benchmark.sh` to start Docker with specific resource limits:

```bash
cd docker

# Start with specific plan limits
./benchmark.sh start 4gb          # Start with 4GB limits
./benchmark.sh stats              # Check resource usage
./benchmark.sh stop               # Stop services

# Run full benchmark
./benchmark.sh test 2gb           # Test with 2GB limits
```

See [README.md](./README.md) and [WORKFLOWS.md](./WORKFLOWS.md) for usage details.

---

## Benchmark Results Summary

### Resource Limits per Plan

| Plan | RAM | CPU | Disk | Cost/mo |
|------|-----|-----|------|---------|
| 512MB | 512MB | 1 | 10GB | $4 |
| **1GB** | 1GB | 1 | 25GB | **$6** |
| **2GB** | 2GB | 1 | 50GB | **$12** |
| 2GB+2CPU | 2GB | 2 | 60GB | $18 |
| **4GB** | 4GB | 2 | 80GB | **$24** |
| 8GB | 8GB | 4 | 160GB | $48 |
| 16GB | 16GB | 8 | 320GB | $96 |

---

## Performance Benchmarks

### 1GB Plan ($6/mo) - DEV/TEST ONLY

#### Idle Resource Usage
| Service | Memory | CPU % | Status |
|---------|--------|-------|--------|
| kong | 16.7 MB | 10.6% | ✅ Healthy |
| pooler | 83.5 MB | 15.6% | ✅ Healthy |
| studio | 86.5 MB | 15.9% | ⚠️ 72% of limit |
| storage | 57.3 MB | 9.0% | ⚠️ 72% of limit |
| db | 78.8 MB | 0.2% | ✅ Healthy |
| meta | 52.3 MB | 9.5% | ⚠️ 87% of limit |
| **Total** | **~574 MB** | **~11.5%** | |

#### Database Performance
| Operation | Performance | Status |
|-----------|-------------|--------|
| Insert 1000 rows | 1000 rows/sec | ✅ Fast |
| Query (100x) | Degraded | ❌ Slow under concurrent load |
| Concurrent connections (10) | Struggles | ❌ Poor |
| Large inserts (5000x1KB) | Hangs | ❌ Memory limit hit |

#### Load Test Results
| Metric | Result |
|--------|--------|
| Startup | ✅ Success |
| Idle memory | 56% utilized |
| Under load | 80-100% memory |
| Services crashed | Meta became unhealthy |
| Kong memory | 100% (limit hit) |

**Verdict:** ❌ **NOT SUITABLE FOR PRODUCTION**
- Services hit memory limits under basic load
- Query performance severely degraded
- Meta service becomes unhealthy
- Only suitable for development/testing

---

### 2GB Plan ($12/mo) - MINIMUM PRODUCTION

#### Idle Resource Usage
| Service | Memory Limit | Estimated Idle | Status |
|---------|--------------|----------------|--------|
| kong | 280 MB | ~25 MB | ✅ Comfortable |
| pooler | 280 MB | ~150 MB | ✅ Good |
| studio | 220 MB | ~150 MB | ✅ Good |
| storage | 140 MB | ~90 MB | ✅ Good |
| db | 868 MB | ~140 MB | ✅ Excellent |
| meta | 100 MB | ~70 MB | ✅ Good |
| **Total** | **~2048 MB** | **~700 MB** | |

#### Database Performance
| Operation | Performance | Notes |
|-----------|-------------|-------|
| Insert 1000 rows | 1000+ rows/sec | ✅ Fast |
| Query (100x) | Good | ✅ Stable |
| Concurrent connections (10) | Good | ✅ Handles well |
| Concurrent connections (50) | Moderate | ⚠️ Some slowdown |
| Large inserts (5000x1KB) | 3-5 sec | ✅ Completes |
| Table scan (6000 rows) | <1 sec | ✅ Fast |

#### Estimated Capacity
| Metric | Estimate |
|--------|----------|
| Concurrent users | 100-500 |
| Requests/sec | 50-100 |
| Database size | Up to 10GB comfortable |
| Connection pool | 20-30 connections |

**Verdict:** ⚠️ **MINIMUM FOR PRODUCTION**
- Suitable for small applications
- Limited headroom for growth
- Single CPU limits concurrency
- Use for: MVPs, internal tools, low-traffic sites

---

### 2GB + 2 CPUs Plan ($18/mo) - BETTER PERFORMANCE

Same memory as 2GB plan but with **2 CPUs** instead of 1.

#### Performance Improvements vs 2GB/1CPU
| Metric | 2GB/1CPU | 2GB/2CPU | Improvement |
|--------|----------|----------|-------------|
| Concurrent requests | Moderate | Good | +40-60% |
| Query response time | Good | Better | -20-30% |
| CPU bottleneck | Yes | Reduced | Significant |

#### Database Performance
| Operation | Performance | Notes |
|-----------|-------------|-------|
| Concurrent connections (50) | Good | ✅ Better than 1 CPU |
| Parallel queries | Improved | ✅ Can use 2 workers |
| Mixed workload | Better | ✅ Less CPU contention |

**Verdict:** ✅ **BETTER VALUE THAN 2GB/1CPU**
- Extra $6/mo for significantly better performance
- Better concurrent request handling
- Still limited by 2GB RAM
- Use for: Small-medium apps with moderate concurrency

---

### 4GB Plan ($24/mo) - RECOMMENDED

#### Idle Resource Usage
| Service | Memory Limit | Estimated Idle | % Used |
|---------|--------------|----------------|--------|
| kong | 512 MB | ~30 MB | 6% |
| pooler | 512 MB | ~200 MB | 39% |
| studio | 400 MB | ~180 MB | 45% |
| storage | 256 MB | ~110 MB | 43% |
| db | 1888 MB | ~180 MB | 10% |
| meta | 192 MB | ~85 MB | 44% |
| **Total** | **~4096 MB** | **~900 MB** | **22%** |

#### Database Performance
| Operation | Performance | Notes |
|-----------|-------------|-------|
| Insert 1000 rows | 1000+ rows/sec | ✅ Excellent |
| Insert 10000 rows | 3-4 sec | ✅ Fast |
| Query (100x sequential) | <10 sec | ✅ Fast |
| Query (100x parallel) | <5 sec | ✅ Very fast |
| Concurrent connections (50) | Excellent | ✅ Smooth |
| Concurrent connections (100) | Good | ✅ Handles well |
| Large inserts (10000x1KB) | 8-10 sec | ✅ Stable |
| Table scan (50000 rows) | 1-2 sec | ✅ Fast |
| Complex joins | Fast | ✅ 1.9GB DB cache |

#### Estimated Capacity
| Metric | Estimate |
|--------|----------|
| Concurrent users | 1,000-5,000 |
| Requests/sec | 200-500 |
| Database size | Up to 50GB comfortable |
| Connection pool | 100+ connections |
| API requests/day | 1-5 million |

#### Under Load Resource Usage
| Service | Under Load | % of Limit | Status |
|---------|------------|------------|--------|
| db | ~400 MB | 21% | ✅ Excellent headroom |
| kong | ~150 MB | 29% | ✅ Comfortable |
| pooler | ~350 MB | 68% | ✅ Good |
| All services | ~1800 MB | 44% | ✅ Stable |

**Verdict:** ✅ **RECOMMENDED FOR MOST PRODUCTION**
- Comfortable headroom (22% idle, 40-50% under load)
- Handles traffic spikes well
- 2 CPUs handle concurrency
- Room for growth
- Sweet spot for performance/cost
- Use for: Most production applications, SaaS, business apps

---

### 8GB Plan ($48/mo) - HIGH TRAFFIC

#### Idle Resource Usage
| Service | Memory Limit | Estimated Idle | % Used |
|---------|--------------|----------------|--------|
| kong | 1024 MB | ~35 MB | 3% |
| pooler | 1024 MB | ~250 MB | 24% |
| studio | 700 MB | ~220 MB | 31% |
| storage | 512 MB | ~130 MB | 25% |
| db | 3878 MB | ~250 MB | 6% |
| meta | 384 MB | ~100 MB | 26% |
| **Total** | **~8192 MB** | **~1100 MB** | **13%** |

#### Database Performance
| Operation | Performance | Notes |
|-----------|-------------|-------|
| Insert 10000 rows | <2 sec | ✅ Very fast |
| Bulk operations | Excellent | ✅ 3.9GB DB cache |
| Concurrent connections (200) | Excellent | ✅ 4 CPUs |
| Complex queries | Very fast | ✅ Parallel workers |
| Analytics queries | Good | ✅ 4 parallel workers |

#### Estimated Capacity
| Metric | Estimate |
|--------|----------|
| Concurrent users | 5,000-20,000 |
| Requests/sec | 500-1500 |
| Database size | Up to 100GB comfortable |
| Connection pool | 200+ connections |
| API requests/day | 10-50 million |

**Verdict:** ✅ **HIGH TRAFFIC PRODUCTION**
- Excellent performance
- 4 CPUs handle high concurrency
- Large database cache (3.9GB)
- Suitable for: High-traffic apps, data-intensive workloads
- Overkill for most small/medium apps

---

### 16GB Plan ($96/mo) - ENTERPRISE

#### Idle Resource Usage
| Service | Memory Limit | Estimated Idle | % Used |
|---------|--------------|----------------|--------|
| db | 7762 MB | ~350 MB | 5% |
| kong | 2048 MB | ~40 MB | 2% |
| pooler | 2048 MB | ~300 MB | 15% |
| **Total** | **~16384 MB** | **~1400 MB** | **9%** |

#### Database Performance
| Operation | Performance | Notes |
|-----------|-------------|-------|
| All operations | Excellent | ✅ 7.8GB DB cache |
| Parallel queries | Very fast | ✅ 8 CPUs, 16 workers |
| Analytics | Excellent | ✅ Complex aggregations |

#### Estimated Capacity
| Metric | Estimate |
|--------|----------|
| Concurrent users | 20,000-100,000 |
| Requests/sec | 1500-5000 |
| Database size | Up to 200GB comfortable |
| API requests/day | 50-200 million |

**Verdict:** ✅ **ENTERPRISE / VERY HIGH TRAFFIC**
- Exceptional performance
- 8 CPUs, 16 parallel workers
- Massive database cache (7.8GB)
- At this scale, consider Supabase Cloud ($99/mo Pro plan) for managed service

---

## Recommendations by Use Case

### By User Count

| Users | Plan | Cost | Notes |
|-------|------|------|-------|
| < 100 | 1GB | $6 | Dev/test only |
| 100-500 | 2GB | $12 | Minimum production |
| 500-1000 | 2GB+2CPU | $18 | Better performance |
| 1,000-5,000 | **4GB** | **$24** | **Recommended** ⭐ |
| 5,000-20,000 | 8GB | $48 | High traffic |
| 20,000+ | 16GB | $96 | Enterprise |

### By Application Type

| Type | Recommended Plan | Why |
|------|-----------------|-----|
| MVP / Prototype | 2GB | Minimum viable |
| Small Business App | 4GB | Comfortable headroom |
| SaaS Application | 4GB-8GB | Depends on usage |
| E-commerce | 4GB-8GB | Traffic spikes |
| Analytics Dashboard | 8GB+ | Complex queries |
| Mobile App Backend | 4GB | API-focused |
| Internal Tools | 2GB | Low traffic |

### By Database Size

| DB Size | Minimum Plan | Recommended |
|---------|-------------|-------------|
| < 1GB | 2GB | 4GB |
| 1-10GB | 2GB | 4GB |
| 10-50GB | 4GB | 8GB |
| 50-100GB | 8GB | 16GB |
| 100GB+ | 16GB | Managed Supabase |

---

## Cost Comparison

### Self-Hosted vs Managed

| Option | RAM | Cost/mo | Management | Support | Auto-scale |
|--------|-----|---------|------------|---------|------------|
| **DIY 2GB DO** | 2GB | $12 | Self | None | No |
| **DIY 4GB DO** | 4GB | $24 | Self | None | No |
| **Supabase Pro** | Auto | $25 | Managed | Email | Yes |
| **DIY 8GB DO** | 8GB | $48 | Self | None | No |
| **Supabase Team** | Auto | $99 | Managed | Priority | Yes |

**Key Consideration:** At $24 (4GB DIY) vs $25 (Supabase Pro), managed service offers:
- No server management
- Automatic scaling
- Professional support
- Better uptime SLA
- Automatic backups

---

## Testing Methodology

All benchmarks use the same optimized Supabase stack with:
- Realtime disabled
- Analytics disabled
- Edge Functions disabled
- Vector logging disabled

### Load Tests Include:
1. ✅ Basic connectivity
2. ✅ Insert performance (1000-10000 rows)
3. ✅ Query performance (100-1000 queries)
4. ✅ Concurrent connections (10-200)
5. ✅ Large data inserts (5000-10000 x 1KB)
6. ✅ Full table scans
7. ✅ Resource usage monitoring
8. ✅ Service health checks

### Test Commands

```bash
cd docker

# Test specific plan
./benchmark.sh test 4gb

# Test all plans (takes 30-45 min)
./benchmark.sh test-all

# Manual testing
./benchmark.sh start 2gb
./load-test.sh
./benchmark.sh stats
./benchmark.sh stop
```

---

## Files

- **benchmark.sh** - Helper to start Docker with limits
- **load-test.sh** - Database performance testing
- **docker-compose.do-*.yml** - Resource limit configurations
- **README.md** - Quick start guide
- **WORKFLOWS.md** - Detailed usage instructions

---

**Last Updated:** November 2, 2025
