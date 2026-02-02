# Phase 3.6: Error Tracking Verification Guide

**Date**: 2026-02-03
**Status**: Testing & Verification Phase
**Purpose**: Verify Sentry error capture across all layers

---

## Pre-Verification Checklist

- [ ] Sentry DSN configured in Railway: `SENTRY_DSN`
- [ ] Sentry environment set: `SENTRY_ENVIRONMENT=production`
- [ ] Code deployed with Phase 3.6 changes
- [ ] Rails server running
- [ ] Test controller routes available at `/test/`

---

## Phase 3.6.1: Installation Verification

### Check Gemfile Installation
```bash
bundle show sentry-ruby
# Should output: /path/to/gems/sentry-ruby-x.x.x
```

### Check Sentry Initialization
```bash
rails console

> defined?(Sentry)
# Should return: "constant"

> Sentry.get_current_scope.dsn
# Should return: "https://key@org.ingest.sentry.io/project_id" (or nil if DSN not set)
```

**Expected Result**: ✅ Sentry is initialized and DSN is loaded

---

## Phase 3.6.2: Controller Error Capture

### Test 1: Trigger Test Error
```bash
# Terminal 1: Start Rails server
bin/rails server

# Terminal 2: Trigger error
curl http://localhost:3000/test/sentry
# Should see: error response

# Check Sentry Dashboard
# Should see: "This is a test error for Sentry verification"
```

**Expected Result**: ✅ Error appears in Sentry within 10 seconds

### Test 2: Verify User Context
```bash
# Login first
# Then trigger error while logged in
curl -H "Cookie: session_id=..." http://localhost:3000/test/sentry

# Check Sentry Dashboard → Event Details
# Should see:
# - User ID
# - User Role
# - Request path, method, IP
```

**Expected Result**: ✅ User context visible in error details

### Test 3: Verify Filtering (RecordNotFound NOT captured)
```bash
# Visit invalid URL
curl http://localhost:3000/invalid-path

# Check Sentry Dashboard
# Should NOT see new "RecordNotFound" error (filtered)
```

**Expected Result**: ✅ RecordNotFound errors are filtered (not captured)

---

## Phase 3.6.2: API Error Capture

### Test API Error
```bash
curl -X GET http://localhost:3000/test/sentry_api

# Check Sentry Dashboard
# Should see error with:
# - API endpoint context
# - Request method, path
# - No sensitive parameters
```

**Expected Result**: ✅ API errors captured with endpoint context

---

## Phase 3.6.2: Background Job Error Capture

### Test Job Error
```bash
rails console

# Method 1: Using test endpoint
> require 'net/http'
> Net::HTTP.get(URI('http://localhost:3000/test/sentry_job'))

# Method 2: Manually queue job
> class TestErrorJob < ApplicationJob
>   queue_as :default
>   def perform
>     raise "Test job error"
>   end
> end
> TestErrorJob.perform_later

# Check Sentry Dashboard
# Should see error with:
# - Job class name
# - Queue name
# - Job arguments
# - Execution count
```

**Expected Result**: ✅ Job errors captured with full context

---

## Phase 3.6.2: JavaScript Error Capture (Browser)

### Test JS Error
1. Open http://localhost:3000/test/sentry_js in browser
2. Click "Click to Trigger Test Error" button
3. Check browser console (F12)
4. Wait 10 seconds
5. Check Sentry Dashboard

**Expected Result**: ✅ JavaScript error appears with browser context

### Verify JS SDK Loaded
```javascript
// Browser console
console.log(window.Sentry)
// Should show: Sentry object with init(), captureException(), etc.
```

**Expected Result**: ✅ Sentry JavaScript SDK initialized

---

## Phase 3.6.3: Admin Dashboard

### Verify Dashboard Section
1. Login as admin
2. Visit `/admin/system`
3. Scroll to "🐛 실시간 에러 추적 (Sentry)" section

**Expected Display**:
- [ ] Error Count (24h) - shows number of errors
- [ ] Error Count (1h) - shows recent errors
- [ ] Error Rate percentage
- [ ] Link to Sentry Dashboard
- [ ] Warning if Sentry not configured

**Expected Result**: ✅ Error tracking section displays correctly

---

## Phase 3.6.4: Alert Notifications

### Test Email Alert (Optional)
1. Configure SMTP settings in Railway
2. Configure alert rule in Sentry Dashboard
3. Trigger test error
4. Wait 1 minute

**Expected Result**: ✅ Email received at `domaman@naver.com`

### Verify Alert Rule Configuration
1. Go to Sentry Dashboard
2. Project Settings → Alerts
3. Should see configured alert rules:
   - [ ] Critical Errors
   - [ ] High Error Rate
   - [ ] New Issues

**Expected Result**: ✅ Alert rules configured and enabled

---

## Performance Impact Verification

### Measure Request Overhead
```bash
# Benchmark with Sentry enabled
time curl http://localhost:3000/

# Should add < 2ms overhead to requests
```

**Expected Result**: ✅ Minimal performance impact

### Check Database Load
```bash
rails console
> puts PerformanceMetric.count
# Should not spike due to Sentry (async)
```

**Expected Result**: ✅ No database load increase

---

## Error Grouping Verification

### Test Error Grouping
1. Trigger the same error multiple times
2. Check Sentry Dashboard
3. Errors should group into single issue

```bash
for i in {1..5}; do curl http://localhost:3000/test/sentry; sleep 1; done
```

**Expected Result**: ✅ Multiple errors grouped into 1 issue

---

## PII & Security Verification

### Check User Context (Should be Safe)
```bash
# Trigger error while logged in
# Check Sentry Dashboard → User section

# Should show:
# - User ID ✅
# - User email (filtered) ✅
# - User role ✅

# Should NOT show:
# - Password ✅
# - API tokens ✅
# - Credit card numbers ✅
```

**Expected Result**: ✅ Only safe fields captured

### Verify Parameter Filtering
```bash
# Make request with sensitive data
curl -X POST http://localhost:3000/api/test \
  -d "password=secret123&api_key=xyz123&email=user@example.com"

# Trigger error
# Check Sentry Dashboard → Request section

# Should show:
# - Filtered params (keys visible, values hidden) ✅
# - No sensitive values in body ✅
```

**Expected Result**: ✅ Sensitive parameters filtered

---

## Full End-to-End Test

### Complete Test Flow
```bash
# 1. Start Rails server
bin/rails server

# 2. Login as admin
# Visit http://localhost:3000/login
# Enter admin credentials

# 3. Trigger various errors
curl http://localhost:3000/test/sentry              # Controller error
curl http://localhost:3000/test/sentry_api          # API error
curl http://localhost:3000/test/sentry_job          # Job error
# Browser: http://localhost:3000/test/sentry_js    # JS error

# 4. Check admin dashboard
# Visit http://localhost:3000/admin/system
# Verify error count displays

# 5. Check Sentry Dashboard
# Visit https://sentry.io/projects/readingpro-rails/
# Should see 4+ issues created

# 6. Verify alert (optional)
# Check email at domaman@naver.com
# Alert email should arrive within 1 minute
```

**Expected Result**: ✅ All error types captured end-to-end

---

## Cleanup After Verification

### Remove Test Endpoints
```bash
# After verification is complete:

# 1. Delete test controller
rm app/controllers/test_controller.rb

# 2. Remove test routes from config/routes.rb
# Delete:
# scope :test do
#   get "sentry", to: "test#sentry"
#   get "sentry_api", to: "test#sentry_api"
#   get "sentry_job", to: "test#sentry_job"
#   get "sentry_js", to: "test#sentry_js"
# end

# 3. Commit and push
git add -A
git commit -m "Phase 3.6: Remove test endpoints after verification"
git push
```

---

## Verification Checklist

### Installation
- [ ] Sentry gems installed (sentry-ruby, sentry-rails)
- [ ] Sentry initializer created and configured
- [ ] DSN configured in Railway environment
- [ ] Rails server starts without errors

### Error Capture
- [ ] Controller errors captured
- [ ] API errors captured with endpoint context
- [ ] Background job errors captured with job context
- [ ] JavaScript errors captured from browser
- [ ] User context included (safe fields only)

### Admin Dashboard
- [ ] Error tracking section displays
- [ ] Sentry dashboard link works
- [ ] Error count updates in real-time

### Filtering & Security
- [ ] RecordNotFound errors NOT captured
- [ ] RoutingError errors NOT captured
- [ ] Passwords NOT captured
- [ ] Tokens NOT captured
- [ ] Sensitive parameters filtered

### Performance
- [ ] Request overhead < 2ms
- [ ] No database load spike
- [ ] No page load performance degradation

### Alerting
- [ ] Alert rules configured in Sentry
- [ ] Email alerts working (optional)
- [ ] Slack alerts working (optional)

---

## Troubleshooting

### Errors Not Appearing in Sentry
1. Check DSN is configured: `echo $SENTRY_DSN`
2. Check environment: `ENV['SENTRY_ENVIRONMENT']`
3. Check Rails logs: `tail -f log/development.log | grep Sentry`
4. Check error level isn't filtered (RecordNotFound, etc.)

### Email Alerts Not Received
1. Verify SMTP settings in `config/environments/production.rb`
2. Check Gmail app password is correct (not regular password)
3. Verify alert rule is configured in Sentry Dashboard
4. Check spam/promotions folder in Gmail

### High CPU/Memory Usage
1. Reduce performance sampling: `config.traces_sample_rate = 0.05`
2. Disable session replay: `config.session_replay_sample_rate = 0`
3. Archive old issues in Sentry Dashboard

### PII Leakage Concern
1. Verify `send_default_pii = false` in sentry.rb
2. Check custom user context doesn't include email
3. Review filtered parameters list

---

## Sign-Off

**Verification Completed**: ___________
**Verified By**: ___________
**All Tests Passing**: ☐ Yes ☐ No
**Ready for Production**: ☐ Yes ☐ No

---

## Next Steps

1. ✅ Remove test endpoints and controller
2. ✅ Deploy to production
3. ✅ Monitor for 24 hours
4. ✅ Review error patterns in Sentry Dashboard
5. ✅ Plan Phase 3.7 (Advanced features)

**Phase 3.7 Recommendation**: Sentry Stats API Integration for real-time error counts on admin dashboard
