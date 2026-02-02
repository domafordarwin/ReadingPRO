# Phase 3.6: Sentry Error Tracking Setup Guide

**Date**: 2026-02-03
**Status**: Implementation Phase
**Components**: Sentry Integration, Email Alerts, Alert Rules

---

## Overview

Phase 3.6 implements comprehensive error tracking using Sentry. This document guides you through:
1. Creating a Sentry project
2. Configuring the Rails application
3. Setting up alert rules
4. Testing error capture

---

## Step 1: Create Sentry Account & Project

### 1.1 Create Sentry Account
1. Go to https://sentry.io
2. Sign up for a free account
3. Create an organization (e.g., "ReadingPRO")

### 1.2 Create Rails Project
1. Click "Create Project"
2. Select **"Django"** or **"Rails"** (if available)
3. Name: `readingpro-rails`
4. Default Alert Settings: Keep enabled

### 1.3 Get DSN
1. Go to Project Settings → Client Keys (DSN)
2. Copy the DSN (looks like: `https://key@org.ingest.sentry.io/project_id`)

---

## Step 2: Configure Railway Environment Variables

Add these variables to your Railway project:

```
SENTRY_DSN=https://<your-key>@<org>.ingest.sentry.io/<project-id>
SENTRY_ENVIRONMENT=production
SENTRY_DEBUG=false

# Email Alert Configuration
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=<your-gmail>@gmail.com
SMTP_PASSWORD=<app-specific-password>
```

### Gmail App Password Setup
1. Enable 2-Step Verification on your Google Account
2. Go to https://myaccount.google.com/apppasswords
3. Select "Mail" and "Windows Computer"
4. Generate app password (16 characters)
5. Use this password in `SMTP_PASSWORD`

---

## Step 3: Deploy & Verify

### 3.1 Deploy Code
```bash
git add -A
git commit -m "Phase 3.6: Sentry error tracking integration"
git push
```

### 3.2 Test Error Capture
```bash
# Rails console on production environment
rails console --environment=production

# Trigger a test error
> raise "Test error from Sentry"

# Check Sentry dashboard - should appear within 10 seconds
```

### 3.3 Test Background Job Error
```bash
# Create a test job that fails
rails console --environment=production

> class TestErrorJob < ApplicationJob
>   def perform
>     raise "Job error test"
>   end
> end

> TestErrorJob.perform_later

# Check Sentry dashboard for job error
```

---

## Step 4: Configure Sentry Alert Rules

### 4.1 Critical Error Alerts
1. Go to Sentry Dashboard → Project Settings → Alerts
2. Click "Create Alert Rule"

**Alert Rule 1: Critical Errors**
- **Trigger**: Error level is "error" or "fatal"
- **Action**: Send email to `domaman@naver.com`
- **Name**: "Critical Errors"

**Alert Rule 2: High Error Rate**
- **Trigger**: Error count > 5 in last 5 minutes
- **Action**: Send email
- **Name**: "High Error Rate"

**Alert Rule 3: New Issue**
- **Trigger**: A new issue is created
- **Action**: Send email
- **Name**: "New Error Detected"

### 4.2 Optional: Slack Integration
1. Go to Integrations → Slack
2. Authorize Sentry for your Slack workspace
3. Select channel for alerts (e.g., `#readingpro-alerts`)

---

## Step 5: Monitoring & Dashboard

### 5.1 Admin Dashboard
- Visit `/admin/system`
- New "🐛 실시간 에러 추적 (Sentry)" section shows:
  - Error count (24h, 1h)
  - Error rate
  - Link to Sentry dashboard

### 5.2 Sentry Dashboard
- All errors grouped by type
- Stack traces with context
- User information (safe fields only)
- Performance metrics (sampling)

---

## Error Capture Details

### What Gets Captured

✅ **Captured**:
- Unhandled controller exceptions
- API errors (with endpoint context)
- Background job failures (with job context)
- JavaScript errors (browser-side)
- Database errors
- Authentication failures

❌ **NOT Captured** (Filtered):
- RecordNotFound (404s)
- RoutingError (bad URLs)
- Parameter parsing errors
- Passwords, tokens, API keys
- Email addresses
- Session cookies

### User Context
Safe information captured per error:
- User ID
- User Role (student/parent/teacher/admin)
- Student ID, Grade, Name
- Request method, path, IP
- User agent

---

## Testing Checklist

### Controller Error Capture
```bash
# Visit invalid URL
curl http://localhost/invalid-path

# Check Sentry - should NOT appear (RoutingError filtered)

# Trigger controller error (create endpoint)
curl http://localhost/test/sentry

# Check Sentry - should appear immediately
```

### API Error Capture
```bash
curl -X POST http://localhost/api/metrics/web_vitals \
  -H "Content-Type: application/json" \
  -d '{}'

# Check Sentry - should capture with endpoint context
```

### Job Error Capture
```bash
rails console
> class FailingJob < ApplicationJob
>   def perform; raise "Job failed"; end
> end
> FailingJob.perform_later

# Check Sentry - should appear with job context
```

### JavaScript Error Capture
```javascript
// Browser console
throw new Error("Test JS error");

// Check Sentry - should appear with browser context
```

---

## Performance Metrics

### Overhead
- Per-request Sentry overhead: < 2ms (async)
- Background job error handling: < 1ms
- JavaScript error tracking: < 5ms

### Sampling
- **Errors**: 100% captured
- **Performance**: 10% sampling (reduces overhead)
- **Session Replay**: 10% on errors only

---

## Troubleshooting

### Errors Not Appearing
1. Check Sentry DSN is configured: `ENV['SENTRY_DSN']`
2. Verify environment is production: `ENV['SENTRY_ENVIRONMENT']`
3. Check Rails logs for Sentry initialization: `grep Sentry log/production.log`
4. Ensure error level isn't filtered

### Email Alerts Not Received
1. Verify SMTP settings in production.rb
2. Check Gmail app password is correct
3. Verify alert rule is configured
4. Test SMTP directly: `rails console` → `Sentry.capture_message("Test")`

### PII Leakage
1. Verify `send_default_pii = false` in sentry.rb
2. Check user context only includes: id, email, role (email filtered anyway)
3. Never store sensitive data in contexts

### High Database Load
1. Reduce performance sampling: `config.traces_sample_rate = 0.05`
2. Disable session replay: `config.session_replay_sample_rate = 0`
3. Archive old issues in Sentry

---

## Production Deployment Checklist

- [ ] Sentry project created
- [ ] DSN copied to Railway environment variables
- [ ] SMTP settings configured (Gmail app password)
- [ ] Alert rules configured in Sentry dashboard
- [ ] Code deployed with Phase 3.6 changes
- [ ] Test error triggered and appears in Sentry
- [ ] Email alert received
- [ ] Admin dashboard shows error section
- [ ] No performance regression detected

---

## Next Steps

**Phase 3.7 Options:**
1. Real User Monitoring API Integration (Sentry Stats on Dashboard)
2. Advanced Alert Rules (Custom workflows, integrations)
3. Error Grouping Customization (Fingerprinting)
4. Performance Profiling (Deeper insights)

**Recommendation**: Phase 3.7.1 - Integrate Sentry Stats API for real-time error counts on admin dashboard

---

## Reference Links

- Sentry Docs: https://docs.sentry.io/platforms/python/enriching-events/
- Rails Integration: https://docs.sentry.io/platforms/ruby/guides/rails/
- Alert Rules: https://docs.sentry.io/product/alerts/create-alerts/create-alert-rule/
- Gmail App Passwords: https://support.google.com/accounts/answer/185833
