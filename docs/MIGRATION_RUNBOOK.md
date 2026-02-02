# ReadingPRO - Database Migration Runbook

**Version**: 1.0.0
**Last Updated**: 2026-02-02
**Status**: Draft - Awaiting Review
**Scope**: Technical debt resolution & data normalization

---

## Table of Contents

1. [Overview](#overview)
2. [Migration Phases](#migration-phases)
3. [Step-by-Step Procedures](#step-by-step-procedures)
4. [Rollback Procedures](#rollback-procedures)
5. [Verification Checklist](#verification-checklist)

---

## Overview

### Scope of Migration

**Current State**: 22 database tables with inconsistencies
**Target State**: 31 normalized tables with complete relationships
**Duration**: 2-3 weeks (phased rollout)
**Risk Level**: Medium (requires testing)

### Why Migrate

1. **Fix Orphaned Code**: Remove broken model references
2. **Restore Models**: Bring back 9 deleted but needed models
3. **Normalize Schema**: Fix incomplete relationships
4. **Fix Seeds File**: Remove invalid references

---

## Migration Phases

### Phase 1: Preparation (Week 1)

**Tasks**:
- Backup production database
- Test migrations locally
- Create feature branch
- Document current state

**Duration**: 2-3 days

### Phase 2: Database Normalization (Week 1-2)

**Tasks**:
- Restore 9 deleted migrations
- Create 2 new migrations
- Fix Seeds file (remove lines 220-226, 356-374)
- Add missing indexes and constraints

**Duration**: 3-5 days

### Phase 3: Code Cleanup (Week 2)

**Tasks**:
- Restore/uncomment models
- Fix controller references
- Update routes if needed
- Run tests

**Duration**: 2-3 days

### Phase 4: Testing & Validation (Week 2-3)

**Tasks**:
- Full regression testing
- Data integrity verification
- Performance validation
- Security audit

**Duration**: 3-5 days

---

## Step-by-Step Procedures

### Phase 1: Preparation

#### Step 1.1: Backup Database

```bash
# Local development
pg_dump readingpro_development > backup_$(date +%Y%m%d_%H%M%S).sql

# Staging (Railway)
railway postgres dump > readingpro_staging_$(date +%Y%m%d).sql

# Production (Railway)
# Use Railway dashboard → Backups → Create Manual Backup
# Keep for 30 days
```

#### Step 1.2: Create Feature Branch

```bash
git checkout -b feature/database-normalization

# Verify branch created
git branch
```

#### Step 1.3: Document Current Schema

```bash
# Export current schema
bin/rails db:schema:dump > db/schema_backup_20260202.rb

# List current tables
bin/rails console
> ActiveRecord::Base.connection.tables.sort
=> ["announcements", "audit_logs", "attempt_reports", ...]
```

---

### Phase 2: Database Normalization

#### Step 2.1: Restore Deleted Migrations

```bash
# Navigate to backup directory
cd db/backup/migrate_old_1769799458/

# List files
ls -la | grep consultation
# Should show:
# 20260129000001_create_consultation_posts.rb
# 20260129000002_create_consultation_comments.rb
# 20260129010245_create_parent_forums.rb
# 20260129010246_create_parent_forum_comments.rb
# 20260129115000_create_consultation_requests.rb
# 20260129115100_create_consultation_request_responses.rb
# 20260129115101_create_notifications.rb

# Copy to current migrations directory (rename with new timestamps)
cp 20260129000001_create_consultation_posts.rb ../migrate/20260202000001_restore_consultation_posts.rb
cp 20260129000002_create_consultation_comments.rb ../migrate/20260202000002_restore_consultation_comments.rb
# ... repeat for other deleted models
```

**Created Files**:
- `db/migrate/20260202000001_restore_consultation_posts.rb`
- `db/migrate/20260202000002_restore_consultation_comments.rb`
- `db/migrate/20260202000003_restore_parent_forums.rb`
- `db/migrate/20260202000004_restore_parent_forum_comments.rb`
- `db/migrate/20260202000005_restore_consultation_requests.rb`
- `db/migrate/20260202000006_restore_consultation_request_responses.rb`
- `db/migrate/20260202000007_restore_notifications.rb`

#### Step 2.2: Create New Migrations

```ruby
# db/migrate/20260202000008_create_evaluation_indicators.rb
class CreateEvaluationIndicators < ActiveRecord::Migration[8.0]
  def change
    create_table :evaluation_indicators do |t|
      t.string :code, null: false
      t.text :name, null: false
      t.text :description
      t.integer :level, default: 1
      t.timestamps
    end

    add_index :evaluation_indicators, :code, unique: true
  end
end

# db/migrate/20260202000009_create_sub_indicators.rb
class CreateSubIndicators < ActiveRecord::Migration[8.0]
  def change
    create_table :sub_indicators do |t|
      t.references :evaluation_indicator, foreign_key: true
      t.string :code
      t.text :name, null: false
      t.text :description
      t.timestamps
    end

    add_index :sub_indicators, [:evaluation_indicator_id, :code], unique: true
  end
end

# db/migrate/20260202000010_create_feedback_prompts.rb
class CreateFeedbackPrompts < ActiveRecord::Migration[8.0]
  def change
    create_table :feedback_prompts do |t|
      t.string :name, null: false
      t.string :category
      t.string :item_type
      t.text :template_text, null: false
      t.jsonb :variables
      t.integer :version, default: 1
      t.boolean :is_active, default: true
      t.references :user, foreign_key: true
      t.timestamps
    end

    add_index :feedback_prompts, :name
    add_index :feedback_prompts, :is_active
  end
end
```

#### Step 2.3: Fix Seeds File

```ruby
# db/seeds.rb - REMOVE these sections:

# Line 220-226: ReaderType (DELETE)
# ReaderType.find_or_create_by!(code: attrs[:code])

# Line 356-366: FeedbackPrompt (DELETE - for now, create in console later)
# FeedbackPrompt.find_or_create_by!(...)

# Line 369-374: References to missing models (DELETE)
# EvaluationIndicator.count
# SubIndicator.count
# ReaderType.count
```

#### Step 2.4: Run Migrations

```bash
# Test locally first
bin/rails db:drop
bin/rails db:create
bin/rails db:migrate

# Verify success
bin/rails console
> Item.first.evaluation_indicator_id  # Should work now
> ConsultationPost.count  # Should be 0 (restored table)
> EvaluationIndicator.count  # Should be 0 (new table)

# Check for errors
# If error occurs, run: bin/rails db:rollback
```

---

### Phase 3: Code Cleanup

#### Step 3.1: Restore Model Classes

```ruby
# app/models/consultation_post.rb
class ConsultationPost < ApplicationRecord
  belongs_to :student
  has_many :consultation_comments, dependent: :destroy

  enum :status, { open: 'open', answered: 'answered', closed: 'closed' }

  validates :title, presence: true, length: { minimum: 5 }
  validates :body, presence: true, length: { minimum: 10 }

  # Visibility control
  def visible_to?(user)
    return true if user.teacher? || user.admin?
    return false if user.parent?  # Parents can't see student consultations
    user.student_id == student_id
  end
end

# app/models/consultation_comment.rb
class ConsultationComment < ApplicationRecord
  belongs_to :consultation_post
  belongs_to :user

  validates :body, presence: true, length: { minimum: 1 }
end

# ... repeat for other restored models
```

**Files to Create**:
- `app/models/consultation_post.rb`
- `app/models/consultation_comment.rb`
- `app/models/parent_forum.rb`
- `app/models/parent_forum_comment.rb`
- `app/models/consultation_request.rb`
- `app/models/consultation_request_response.rb`
- `app/models/notification.rb`
- `app/models/evaluation_indicator.rb`
- `app/models/sub_indicator.rb`
- `app/models/feedback_prompt.rb`

#### Step 3.2: Verify Controllers Still Work

```bash
# Controllers should already exist (were not deleted)
# Just verify they can load without errors

bin/rails console
> Researcher::ItemsController.new
> Student::ConsultationsController.new  # Should work now

# Test in browser
bin/rails server
# Visit http://localhost:3000/student/consultations
# Should render without error
```

#### Step 3.3: Update Routes if Needed

```ruby
# config/routes.rb - verify these exist

namespace :student do
  resources :consultations  # Should already exist
end

namespace :parent do
  resources :forums  # Should already exist
end

# Check routes
bin/rails routes | grep consultation
bin/rails routes | grep forum
```

---

### Phase 4: Testing & Validation

#### Step 4.1: Run Test Suite

```bash
# Run all tests
bin/rails test

# Expected output:
# 150+ tests passing
# 0 failures
# 0 errors

# If failures occur:
# 1. Read error message carefully
# 2. Check if test fixture needs updating
# 3. Fix test or code
# 4. Re-run
```

#### Step 4.2: Data Integrity Verification

```ruby
# bin/rails console

# Verify relationships work
item = Item.first
puts item.evaluation_indicator_id  # Should not be nil
puts item.stimulus_id  # May be nil (optional)

# Verify restored tables work
ConsultationPost.create!(
  student_id: 54,
  title: "Test consultation",
  body: "This is a test"
)

# Verify new tables work
EvaluationIndicator.create!(
  code: "국어.2-1-01",
  name: "글의 주제와 목적 파악"
)

# Run seeds to populate initial data
exit
bin/rails db:seed
```

#### Step 4.3: Performance Validation

```bash
# Check query performance
bin/rails console

# Time a complex query
start = Time.now
items = Item.includes(:stimulus, :evaluation_indicator, :item_choices).where(status: 'active')
puts Time.now - start
# Should be <100ms

# Check database stats
> Item.count  # Should match expected count
> ConsultationPost.count  # Should be 0 initially
> EvaluationIndicator.count  # Should be populated after seed
```

#### Step 4.4: Security Audit

```bash
# Check for SQL injection vulnerabilities
bin/brakeman --no-pager

# Check for dependency vulnerabilities
bin/bundler-audit

# Review new models for secure practices
# - All user inputs validated
# - Sensitive data not logged
# - Authorization checks present
```

---

### Phase 5: Deployment

#### Step 5.1: Create Pull Request

```bash
# Commit changes
git add -A
git commit -m "Migrate: Restore 9 models, normalize database schema

- Restore 7 deleted migrations (consultation posts, forums, requests)
- Create 3 new migrations (evaluation indicators, feedback prompts)
- Fix seeds.rb (remove invalid references)
- Update models with relationships
- All tests passing

Closes #456
Resolves technical debt from database refactoring"

# Push to GitHub
git push origin feature/database-normalization

# Create PR with:
# - Clear description of changes
# - List of new tables
# - Breaking changes (none)
# - Testing steps
# - Rollback plan
```

#### Step 5.2: Staging Deployment

```bash
# Merge PR to staging branch
git push origin feature/database-normalization:staging

# Wait for CI to pass
# Monitor staging deployment

# Test in staging environment
# - Login as teacher
# - Create consultation post
# - Create forum post
# - View reports
```

#### Step 5.3: Production Deployment

```bash
# If staging tests pass:
git checkout main
git merge feature/database-normalization
git push origin main

# Monitor production deployment
# - Check logs for errors
# - Verify database migrations completed
# - Test critical paths
# - Monitor error rates

# Total downtime: 0-5 minutes (migrations run as part of deployment)
```

---

## Rollback Procedures

### If Migration Fails Before Deployment

```bash
# Simply don't merge the PR
git checkout main
git branch -D feature/database-normalization
# Start over with fixes

# Or reset to before the commit
git reset --hard origin/main
```

### If Migration Fails During Deployment

```bash
# Option 1: Rollback via Railway dashboard
# 1. Go to Deployments
# 2. Click "Rollback" on previous working version
# This brings back the old code and database schema

# Option 2: Manual rollback
bin/rails db:rollback

# Then re-deploy fixed code
git push origin main
```

### If Data Corruption Detected Post-Deployment

```bash
# 1. Take application offline (scale to 0)
# 2. Restore database from backup (pre-migration)
# 3. Fix root cause in code
# 4. Test fixes thoroughly locally
# 5. Deploy fixed code
# 6. Restore application

# Commands:
railway scale web=0  # Take offline
# Restore from backup in Railway dashboard
railway scale web=1  # Bring back online
```

---

## Verification Checklist

### Pre-Migration

- [ ] Development environment clean (git status clean)
- [ ] All tests passing locally
- [ ] RuboCop passing
- [ ] Brakeman passing
- [ ] Bundler Audit passing
- [ ] Backup created (local + staging + production)
- [ ] Feature branch created

### During Migration

- [ ] Migrations run successfully
- [ ] No SQL errors in migration output
- [ ] Schema matches expected (31 tables)
- [ ] Seeds file runs without errors
- [ ] All relationships load correctly

### Post-Migration

- [ ] All tests still passing
- [ ] Controllers don't error on startup
- [ ] Can navigate all portal pages
- [ ] Database queries under 200ms
- [ ] No N+1 queries detected
- [ ] Brakeman still passing
- [ ] Application logs show no errors
- [ ] Health check endpoint returns 200

### Data Integrity

- [ ] Item count unchanged
- [ ] Student attempt count unchanged
- [ ] Response count unchanged
- [ ] No data loss in migration
- [ ] Foreign key constraints satisfied
- [ ] Unique constraints still valid

---

## Estimated Timeline

| Phase | Tasks | Duration | Start Date | End Date |
|---|---|---|---|---|
| **Phase 1** | Preparation | 2-3 days | Feb 3 | Feb 5 |
| **Phase 2** | Database Normalization | 3-5 days | Feb 6 | Feb 10 |
| **Phase 3** | Code Cleanup | 2-3 days | Feb 11 | Feb 13 |
| **Phase 4** | Testing | 3-5 days | Feb 13 | Feb 17 |
| **Phase 5** | Deployment | 1 day | Feb 18 | Feb 18 |
| **Phase 6** | Monitoring | 1 week | Feb 18 | Feb 25 |

**Total**: 2-3 weeks

---

## Troubleshooting

| Issue | Symptoms | Solution |
|---|---|---|
| **Migration Won't Run** | `PG::UndefinedTable` error | Ensure previous migrations succeeded: `bin/rails db:migrate:status` |
| **Foreign Key Violation** | `PG::ForeignKeyViolation` | Migration depends on other data. Check migration order. |
| **Unique Constraint Violation** | Migration fails on unique constraint | Duplicate data exists. Clean data before migration. |
| **Seeds File Fails** | `NameError: uninitialized constant` | Removed deleted model reference. Verify seeds.rb. |
| **Tests Fail After Migration** | Model tests error | Update fixtures in `test/fixtures/` to match new schema. |

---

## Post-Migration Tasks

### Week 1 After Migration

- [ ] Monitor error logs for issues
- [ ] Watch for performance regressions
- [ ] Verify all user functions work
- [ ] Collect user feedback

### Week 2-4 After Migration

- [ ] Run full regression testing
- [ ] Verify data backups working
- [ ] Plan Phase 2 improvements:
  - [ ] Extract Query Objects
  - [ ] Add Pundit policies
  - [ ] Implement background jobs

---

## Document History

| Version | Date | Changes |
|---|---|---|
| 0.1 | 2026-02-02 | Initial migration runbook |
| 1.0 | TBD | Final version after migration |

---

**This runbook provides step-by-step procedures to safely migrate the database while maintaining data integrity and system stability. Execute carefully and follow the verification checklist at each step.**
