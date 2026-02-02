# ReadingPRO - Deployment Guide

**Version**: 1.0.0
**Last Updated**: 2026-02-02
**Status**: Draft - Awaiting Review
**Platform**: Railway (Primary), AWS (Future Alternative)

---

## Table of Contents

1. [Deployment Architecture](#deployment-architecture)
2. [Pre-Deployment Checklist](#pre-deployment-checklist)
3. [Staging Deployment](#staging-deployment)
4. [Production Deployment](#production-deployment)
5. [Monitoring & Maintenance](#monitoring--maintenance)
6. [Rollback Procedures](#rollback-procedures)
7. [Environment Configuration](#environment-configuration)

---

## Deployment Architecture

### Current: Railway (Recommended)

```
GitHub Repository
       ↓
   Push/Merge to main
       ↓
   GitHub Actions CI
       ↓ (if pass)
   Railway Auto-Deploy
       ↓
PostgreSQL (Railway plugin)
Redis (optional)
Docker Container (Puma)
       ↓
CDN (static assets)
       ↓
User
```

### Infrastructure Components

| Component | Technology | Purpose |
|---|---|---|
| **Hosting** | Railway | Container orchestration |
| **Database** | PostgreSQL 16 | Persistent data storage |
| **Cache** | Redis | Session storage, caching |
| **Assets** | Railway CDN | Static file distribution |
| **Domain** | Cloudflare | DNS, SSL, DDoS protection |
| **Email** | SendGrid (future) | Transactional emails |
| **Monitoring** | DataDog (future) | Performance monitoring |

---

## Pre-Deployment Checklist

### Code Quality

- [ ] All tests passing: `bin/rails test`
- [ ] No RuboCop violations: `bin/rubocop`
- [ ] No security issues: `bin/brakeman --no-pager`
- [ ] No dependency vulnerabilities: `bin/bundler-audit`
- [ ] Code review approved (1+ reviewer)

### Database Migrations

- [ ] All migrations tested locally
- [ ] Backward compatibility verified
- [ ] No long-running migrations (>5 min)
- [ ] Rollback plan documented

### Documentation

- [ ] CHANGELOG.md updated
- [ ] README.md reflects changes
- [ ] API docs updated if endpoints changed
- [ ] Database schema documented

### Configuration

- [ ] Environment variables documented
- [ ] Secrets rotated if needed
- [ ] Feature flags configured
- [ ] Rate limits configured

### Testing

- [ ] Manual testing completed
- [ ] Cross-browser testing done
- [ ] Performance impact assessed
- [ ] Security implications reviewed

---

## Staging Deployment

### Purpose

Staging is production-like environment for final testing before production release.

### Staging Environment Setup

```bash
# Railway Staging Project
# https://railway.app/project/[STAGING_ID]

# Environment variables
DATABASE_URL=postgresql://user:pass@staging-db/readingpro_staging
RAILS_ENV=staging
REDIS_URL=redis://[STAGING_REDIS]
OPENAI_API_KEY=[STAGING_KEY]
```

### Deploy to Staging

```bash
# Option 1: Direct push to staging branch
git push origin main:staging
# Railway auto-deploys on push to staging branch

# Option 2: Manual Railway deploy
# 1. Open Railway dashboard
# 2. Select staging project
# 3. Click "Deploy latest commit"

# Option 3: CLI
railway deploy --stage staging
```

### Verify Staging Deployment

```bash
# Test critical paths
curl https://readingpro-staging.railway.app/login
curl -X GET https://readingpro-staging.railway.app/api/v1/items

# Check database migrations
# https://readingpro-staging.railway.app/health

# Monitor logs
railway logs --follow
```

### Staging Testing Checklist

- [ ] Login works (all roles)
- [ ] Student can take assessment
- [ ] Teacher can score responses
- [ ] API endpoints responding correctly
- [ ] Database queries performant
- [ ] Error handling working
- [ ] Notifications sending (if applicable)

### Rollback from Staging

```bash
# Railway dashboard → Deployments → Previous version → Rollback
```

---

## Production Deployment

### Pre-Production Steps

1. **Approval**: Get stakeholder sign-off
2. **Notification**: Notify users of maintenance window (if needed)
3. **Backup**: Trigger database backup

### Production Deployment Process

```bash
# 1. Ensure main branch is ready
git status  # Clean working directory
git log --oneline -5  # Verify recent commits

# 2. Tag release
git tag -a v1.2.0 -m "Release version 1.2.0"
git push origin v1.2.0

# 3. Push to production
git push origin main
# Railway auto-deploys on main branch

# 4. Monitor deployment
railway logs --follow
railway status
```

### Railway Production Deployment

```yaml
# railway.toml configuration
[build]
builder = "nix"

[deploy]
startCommand = "bin/rails s"
restartPolicyType = "always"
healthcheckPath = "/health"
healthcheckInterval = 30

[env]
RAILS_ENV = "production"
RAILS_SERVE_STATIC_FILES = 1
```

### Post-Deployment Verification

```bash
# 1. Health check
curl https://readingpro.railway.app/health
# Expected: { "status": "ok", "database": "connected" }

# 2. Smoke tests (critical paths)
curl -X POST https://readingpro.railway.app/login \
  -d "email=teacher@test&password=password"

curl -X GET "https://readingpro.railway.app/api/v1/items?page=1" \
  -H "Authorization: Bearer token"

# 3. Database connection
curl https://readingpro.railway.app/admin/system

# 4. Monitor error rates
# Check DataDog/New Relic for error spikes
```

### Production Rollback

```bash
# If critical issue detected

# Option 1: Rollback via Railway dashboard
# Deployments → Previous working version → Rollback

# Option 2: Rollback via CLI
railway rollback [DEPLOYMENT_ID]

# Option 3: Re-deploy previous tag
git checkout v1.1.0
git push origin HEAD:main --force-with-lease
```

---

## Monitoring & Maintenance

### Health Checks

```ruby
# app/controllers/health_controller.rb
class HealthController < ApplicationController
  skip_before_action :authenticate

  def show
    render json: {
      status: 'ok',
      database: check_database,
      redis: check_redis,
      timestamp: Time.current
    }
  end

  private

  def check_database
    ActiveRecord::Base.connection.active? ? 'connected' : 'disconnected'
  rescue
    'error'
  end

  def check_redis
    Rails.cache.exist?('health_check') ? 'connected' : 'disconnected'
  rescue
    'error'
  end
end

# config/routes.rb
get '/health', to: 'health#show'
```

### Logging & Monitoring

```ruby
# config/initializers/logging.rb
if Rails.env.production?
  # Structured logging
  require 'logger'
  LOGGER = Logger.new($stdout)
  LOGGER.level = Logger::INFO

  # Format: JSON for parsing
  LOGGER.formatter = ->(severity, datetime, progname, msg) {
    {
      timestamp: datetime.iso8601,
      level: severity,
      message: msg,
      app: 'readingpro'
    }.to_json
  }
end

# Usage
Rails.logger.info("Assessment attempt started: #{attempt.id}")
```

### Performance Monitoring

```ruby
# config/initializers/rack_mini_profiler.rb
Rack::MiniProfiler.config.start_hidden = true  # Production
Rack::MiniProfiler.config.skip_paths = ['/health', '/api/']
```

### Database Maintenance

```bash
# Monthly: Analyze and vacuum
railway postgres exec 'VACUUM ANALYZE;'

# Monitor table sizes
railway postgres exec '
  SELECT schemaname, tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||"."||tablename)) as size
  FROM pg_tables
  ORDER BY pg_total_relation_size(schemaname||"."||tablename) DESC
  LIMIT 10;'
```

### Backup Strategy

```
Frequency: Daily (automated)
Retention: 30 days
Location: Railway automated backups + AWS S3 (future)

Restore procedure:
1. Contact Railway support for point-in-time recovery
2. Or: Download backup, test locally, then restore
```

---

## Environment Configuration

### Environment Variables (Production)

```bash
# database
DATABASE_URL=postgresql://user:hash@host:5432/readingpro_production

# rails
RAILS_ENV=production
RAILS_MASTER_KEY=[20-char encrypted master key]
RAILS_SERVE_STATIC_FILES=1

# external APIs
OPENAI_API_KEY=sk-[key]
SENDGRID_API_KEY=[key]

# caching
REDIS_URL=redis://[host]:6379/0

# monitoring (future)
DATADOG_API_KEY=[key]
NEW_RELIC_LICENSE_KEY=[key]

# security
ALLOWED_HOSTS=readingpro.railway.app,readingpro.com
CORS_ORIGINS=https://readingpro.com
```

### Master Key Management

```bash
# Generate master key (Rails already does this)
bin/rails credentials:show  # View current
bin/rails credentials:edit  # Edit encrypted credentials

# Production master key must be in Railway environment variable
# RAILS_MASTER_KEY=[contents of config/master.key]

# Never commit config/master.key to git
echo 'config/master.key' >> .gitignore
```

### Secrets Management (Future)

Use Rails credentials for secrets instead of .env:

```bash
# Encrypt secrets
bin/rails credentials:edit

# In terminal, add:
sendgrid:
  api_key: sk-...

openai:
  api_key: sk-...
```

Then reference in code:

```ruby
Rails.application.credentials.openai&.api_key
```

---

## Scaling Strategy

### Current: Single Container

```
1 Container (Puma)
├── 5 worker processes
└── 10 threads per worker
= Handle ~1000 concurrent connections
```

### Phase 1: Add Redis Caching

```
User Request
    ↓
Rails App (checked Redis first)
    ↓
PostgreSQL (if cache miss)
```

### Phase 2: Multiple Containers (Kubernetes)

```
Load Balancer
├── Container 1 (app + api)
├── Container 2 (background jobs)
└── Container 3 (data processing)
    ↓
PostgreSQL Read Replicas
    ↓
Redis Cluster
```

### Phase 3: CDN for Static Assets

```
CloudFront
├── app.js
├── app.css
└── images/
    ↓ (cache hit)
    Returns immediately (99% cases)
    ↓ (cache miss)
    Origin: Railway S3
```

---

## Disaster Recovery

### RTO & RPO Targets

| Scenario | RTO (Recovery Time) | RPO (Recovery Point) |
|---|---|---|
| **Database Failure** | 1 hour | 1 day (backup) |
| **Complete App Failure** | 30 minutes | Latest commit |
| **Data Corruption** | 4 hours | 7 days (backup) |

### Recovery Procedures

**Database Failure**:
1. Check Railway dashboard for database status
2. If unavailable, contact Railway support
3. Restore from automated backup (within 24 hours)
4. Verify data integrity
5. Notify users if data loss

**Application Failure**:
1. Check deployment logs
2. Verify all migrations completed
3. Rollback to previous working version
4. Investigate root cause
5. Deploy fix

**Data Corruption**:
1. Take database offline (stop app)
2. Restore from clean backup
3. Verify restore integrity
4. Bring app back online
5. Sync any missing data

---

## CI/CD Pipeline

### GitHub Actions

```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16
        options: --health-cmd pg_isready
    steps:
      - uses: actions/checkout@v3
      - uses: ruby/setup-ruby@v1
      - run: bundle install
      - run: bin/rails test
      - run: bin/rubocop
      - run: bin/brakeman --no-pager

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v3
      - run: curl https://railway.app/deploy | sh
        env:
          RAILWAY_TOKEN: ${{ secrets.RAILWAY_TOKEN }}
```

---

## Troubleshooting

| Problem | Symptoms | Solution |
|---|---|---|
| **Slow Deploy** | Takes >10 min | Check asset compilation, dependencies |
| **Migration Failed** | Release command error | Rollback, fix migration, re-deploy |
| **High Memory Usage** | OOM kills | Reduce worker count, increase container size |
| **Database Connection Pool Exhausted** | "too many connections" error | Increase pool size, check for connection leaks |
| **Static Files Not Loading** | 404 on CSS/JS | Ensure RAILS_SERVE_STATIC_FILES=1 |

---

## Security Checklist

- [ ] HTTPS enabled (auto via Railway)
- [ ] CSRF protection enabled
- [ ] XSS protection headers set
- [ ] SQL injection prevention (parameterized queries)
- [ ] Sensitive data not logged
- [ ] Secrets encrypted (Rails credentials)
- [ ] Regular security updates (Brakeman, Bundler Audit)
- [ ] Access logs enabled for audit trail

---

## Release Process

### 1. Prepare Release

```bash
# Update version
echo "1.2.0" > VERSION

# Update CHANGELOG
# Entry format: [Unreleased] → [1.2.0] - 2026-02-03
# - Feature: Description
# - Fix: Description
# - Chore: Description

git add VERSION CHANGELOG.md
git commit -m "Release 1.2.0"
git tag -a v1.2.0 -m "Version 1.2.0"
```

### 2. Deploy to Staging

```bash
git push origin main:staging
# Wait for green checkmark on GitHub Actions
```

### 3. Test in Staging

```bash
# Run acceptance tests
# Test critical user flows
# Performance verification
```

### 4. Deploy to Production

```bash
git push origin main
git push origin v1.2.0
```

### 5. Post-Release

```bash
# Monitor error rates for 1 hour
# Check user feedback
# Update status page
# Create release notes
```

---

## Document History

| Version | Date | Changes |
|---|---|---|
| 0.1 | 2026-02-02 | Initial deployment guide |
| 1.0 | TBD | Final version after deployment |

---

**This guide ensures consistent, safe, and reliable deployments to production. Follow these procedures carefully to maintain system stability and minimize downtime.**
