# Phase 3.7: Sentry API Integration - Setup Guide

**Date**: 2026-02-03
**Status**: Implementation Phase
**Purpose**: Real-time error statistics on admin dashboard

---

## Overview

Phase 3.7 integrates Sentry's REST API to fetch real-time error statistics and display them on the admin dashboard. This eliminates placeholder data and provides live error counts, rates, and trending information.

---

## What Gets Displayed

### Admin Dashboard (`/admin/system`)

The error tracking section now shows:
- **최근 24시간 에러**: Total errors in last 24 hours
- **최근 1시간 에러**: Total errors in last 1 hour
- **에러율**: Percentage of requests with errors
- **가장 빈번한 에러**: Most common error type/message

---

## Setup Steps

### Step 1: Generate Sentry API Token

1. Go to **Sentry Dashboard** → https://sentry.io
2. Click **Settings** → **API tokens** (or Organization settings)
3. Click **Create New Token**
4. Configure permissions:
   - ✅ `project:read`
   - ✅ `project:admin` (recommended for full access)
   - ✅ `org:read`
5. Copy the token (format: `sntrys_...`)

**Recommended Token Scope**: Organization-level for all projects

### Step 2: Get Organization & Project Slugs

1. In Sentry Dashboard, note the URL pattern:
   ```
   https://sentry.io/organizations/{ORG_SLUG}/issues/
   ```
   → Copy `{ORG_SLUG}` (usually lowercase, e.g., "readingpro")

2. For project slug:
   ```
   https://sentry.io/projects/{ORG_SLUG}/{PROJECT_SLUG}/
   ```
   → Copy `{PROJECT_SLUG}` (usually lowercase, e.g., "readingpro-rails")

### Step 3: Set Railway Environment Variables

Add these to your Railway project settings:

```
SENTRY_AUTH_TOKEN=sntrys_...
SENTRY_ORG_SLUG=readingpro
SENTRY_PROJECT_SLUG=readingpro-rails
```

### Step 4: Test the Integration

#### Option A: Rails Console
```bash
rails console --environment=production

# Test Sentry Service
> service = SentryService.new
> stats = service.fetch_error_stats
> puts stats.inspect

# Expected output (if errors exist in Sentry):
# {:error_count_24h=>5, :error_count_1h=>1, :error_rate=>2.5, :most_common_error=>"...", :sentry_enabled=>true}

# Expected output (if no errors):
# {:error_count_24h=>0, :error_count_1h=>0, :error_rate=>0.0, :most_common_error=>nil, :sentry_enabled=>true}
```

#### Option B: Browser Test
1. Deploy code to production
2. Login as admin
3. Visit `/admin/system`
4. Scroll to "🐛 실시간 에러 추적" section
5. Should show real error counts (not 0)

---

## Sentry API Endpoints Used

### Events API
```
GET /api/0/projects/{org_slug}/{project_slug}/events/
```
- Fetches error events from specified time period
- Used for: error count calculation

### Issues API
```
GET /api/0/projects/{org_slug}/{project_slug}/issues/
```
- Fetches issue (error) details
- Used for: most common error identification

### Stats API
```
GET /api/0/projects/{org_slug}/{project_slug}/stats/
```
- Fetches statistical aggregates
- Used for: error rate calculation

---

## Error Handling & Fallback

### If API Token Not Set
```
SENTRY_AUTH_TOKEN not configured
→ Display placeholder data (0 errors)
→ Warning: "Sentry API not configured"
```

### If API Call Fails
```
Network error / Timeout / Invalid credentials
→ Log error to Rails logger
→ Display last known stats or 0
→ Graceful degradation (doesn't break dashboard)
```

### If Sentry Project Not Found
```
404 response from Sentry API
→ Log error: "Sentry project not found"
→ Display placeholder data
→ Check SENTRY_ORG_SLUG and SENTRY_PROJECT_SLUG
```

---

## API Rate Limits

Sentry API limits:
- **Free plan**: 500 requests/minute
- **Pro plan**: Unlimited

Dashboard refresh interval:
- **Per page load**: 1 API call to fetch all stats
- **Recommended frequency**: No auto-refresh (on demand)
- **Impact**: Negligible on rate limit

---

## Performance Impact

### API Call Overhead
- **Latency**: 200-500ms (depending on Sentry server load)
- **Impact**: Admin page load ~500ms slower
- **Solution**: Async refresh (future enhancement)

### Caching Strategy
Currently: **No caching** (real-time data)

Future optimization options:
1. Cache stats for 5 minutes (good balance)
2. Background job to fetch stats (async update)
3. WebSocket for live updates (advanced)

---

## Development vs Production

### Development
```
# No API calls (logs only)
SentryService runs but returns 0 values
Allows testing without Sentry account
```

### Staging/Production
```
# Real API calls
Fetch actual error stats from Sentry
Display on admin dashboard
Monitor production errors in real-time
```

---

## Testing Checklist

- [ ] SENTRY_AUTH_TOKEN set in Railway
- [ ] SENTRY_ORG_SLUG matches organization slug
- [ ] SENTRY_PROJECT_SLUG matches project slug
- [ ] Rails server starts without errors
- [ ] `/admin/system` page loads
- [ ] Error counts display (not 0 or error)
- [ ] Sentry dashboard link works
- [ ] Most common error displays

---

## Troubleshooting

### "Sentry API not configured" Warning
**Solution**: Set `SENTRY_AUTH_TOKEN` environment variable

```bash
# Check if set:
echo $SENTRY_AUTH_TOKEN

# Should output: sntrys_...
```

### Error Count Shows 0 (Expected)
**Solution**: This is normal if no errors have occurred
- Create test error: `curl http://localhost/test/sentry`
- Wait 30 seconds for Sentry to process
- Refresh dashboard

### "Sentry project not found"
**Solution**: Check organization and project slugs

```bash
# Verify values:
echo $SENTRY_ORG_SLUG
echo $SENTRY_PROJECT_SLUG

# Check against:
# https://sentry.io/organizations/{ORG_SLUG}/issues/
# https://sentry.io/projects/{ORG_SLUG}/{PROJECT_SLUG}/
```

### API Token Authentication Failed
**Solution**: Regenerate token with correct permissions

1. Delete old token: Sentry → Settings → API tokens
2. Create new token with `project:read`, `org:read`
3. Update SENTRY_AUTH_TOKEN in Railway

### Slow Dashboard Load
**Solution**: API calls are taking > 500ms

Options:
1. Check Sentry server status
2. Use smaller time range (1h instead of 24h)
3. Implement caching (Phase 3.8)
4. Use async background job (Phase 3.8)

---

## Next Enhancements (Phase 3.8+)

### Short-term
1. **Caching**: Cache stats for 5 minutes
2. **Async Update**: Background job to fetch stats
3. **Error Trending**: Show hourly breakdown

### Medium-term
1. **Real-time Updates**: WebSocket or Turbo Stream
2. **Custom Queries**: Filter by error type, endpoint
3. **Alerting**: Automatic email if error rate spikes

### Long-term
1. **ML-based Anomalies**: Detect unusual patterns
2. **Integration**: Connect to incident management
3. **Advanced Reports**: Export error trends

---

## API Reference

### SentryService Methods

#### `fetch_error_stats`
Returns complete error statistics for dashboard.

```ruby
service = SentryService.new
stats = service.fetch_error_stats

# Returns:
{
  error_count_24h: 42,
  error_count_1h: 3,
  error_rate: 2.5,  # percentage
  most_common_error: "RuntimeError: Something went wrong (42 occurrences)",
  sentry_enabled: true,
  last_updated: Time.current
}
```

#### `fetch_error_count(duration)`
Get error count for specified duration.

```ruby
count_24h = service.fetch_error_count(24.hours)
count_1h = service.fetch_error_count(1.hour)
```

#### `fetch_error_rate`
Get percentage of requests with errors.

```ruby
rate = service.fetch_error_rate  # Returns: 2.5 (percent)
```

#### `fetch_most_common_error`
Get the most frequently occurring error.

```ruby
error = service.fetch_most_common_error
# Returns: "RuntimeError: Something went wrong (42 occurrences)"
```

---

## Configuration Reference

### Environment Variables
| Variable | Required | Format | Example |
|----------|----------|--------|---------|
| `SENTRY_DSN` | Yes | URL | `https://key@org.ingest.sentry.io/project` |
| `SENTRY_AUTH_TOKEN` | Yes (for API) | Token | `sntrys_abc123...` |
| `SENTRY_ORG_SLUG` | Yes (for API) | Slug | `readingpro` |
| `SENTRY_PROJECT_SLUG` | Yes (for API) | Slug | `readingpro-rails` |
| `SENTRY_ENVIRONMENT` | No | Env | `production` |

### Rails Configuration
All configuration handled in:
- `config/initializers/sentry.rb` (error capture)
- `app/services/sentry_service.rb` (API integration)
- `app/controllers/admin/system_controller.rb` (display)

---

## Security Notes

### API Token Security
- **Keep secret**: Never commit to Git
- **Use env vars**: Only accessible in production
- **Rotate regularly**: Change token every 90 days
- **Limit scope**: Use `project:read` only if possible

### Data Privacy
- No PII in Sentry (enforced via `send_default_pii: false`)
- Error messages may contain non-sensitive context
- Admin only: Stats page is admin-protected

---

## Monitoring

### How to Monitor API Integration
1. Check Rails logs for `[SentryService]` messages
2. Monitor admin dashboard for stat changes
3. Set up Sentry webhooks for critical errors
4. Review error patterns weekly

### Health Check
```bash
# Production verification
curl https://app.railway.app/admin/system

# Check error tracking section displays
# Verify error counts are not 0 or error messages
```

---

## Completion Checklist

- [ ] SENTRY_AUTH_TOKEN generated and set
- [ ] SENTRY_ORG_SLUG set correctly
- [ ] SENTRY_PROJECT_SLUG set correctly
- [ ] Code deployed to production
- [ ] Admin dashboard shows real error counts
- [ ] No API errors in Rails logs
- [ ] Tested with production Sentry data

---

## Sign-Off

**Phase 3.7 Implementation**: Complete ✅
**Status**: Ready for production deployment
**Next Phase**: Phase 3.8 - Caching & Async Updates
