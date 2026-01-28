# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ReadingPRO is a reading proficiency diagnostics and assessment system built with Rails 8.1 + PostgreSQL, deployed on Railway.

## Common Commands

```bash
# Development
bundle install
bin/rails db:prepare
bin/rails server

# Testing
bin/rails test                    # unit tests
bin/rails test:system             # system tests (Capybara + Selenium)
bin/rails test test/models/item_test.rb  # single test file

# Linting & Security
bin/rubocop                       # Ruby style checks
bin/rubocop -a                    # auto-fix
bin/brakeman --no-pager           # Rails security scan
bin/bundler-audit                 # gem vulnerability scan
bin/importmap audit               # JS dependency audit

# Database
bin/rails db:migrate
bin/rails db:test:prepare

# Import (XLSX data loading)
bundle exec rails runner script/import_literacy_bank.rb path/to/file.xlsx --dry-run
bundle exec rails runner script/import_literacy_bank.rb path/to/file.xlsx
```

## Architecture

### Layer Structure
- **Presentation**: Admin SSR at `/admin` using Rails Views (ERB)
- **Application**: Service layer (`app/services/`) for business logic
- **Domain**: ActiveRecord models with PostgreSQL

### Key Domain Models

**Assessment Content:**
- `ReadingStimulus` → `stimuli` table (reading passages). Named to avoid collision with Hotwire Stimulus.
- `Item` → test questions (MCQ or constructed response)
- `ItemChoice` / `ChoiceScore` → MCQ options and scoring
- `Rubric` / `RubricCriterion` / `RubricLevel` → constructed response scoring rubrics

**Test Administration:**
- `Form` → test forms composed of items
- `FormItem` → items within a form (with position and points)
- `Attempt` → a user's test session
- `Response` / `ResponseRubricScore` → answers and scores

### Scoring Logic
- MCQ: automatic scoring via `ChoiceScore.score_percent`
- Constructed: rubric-based scoring (criteria × levels)
- All scoring logic in `ScoreResponseService`

### Custom Inflections
Defined in `config/initializers/inflections.rb`:
- stimulus ↔ stimuli
- criterion ↔ criteria

### Routes
- `/` → welcome page
- `/admin` → admin dashboard (items, stimuli, forms, attempts, scoring)

## Environment Variables (Production)
- `DATABASE_URL` - PostgreSQL connection (Railway plugin)
- `RAILS_MASTER_KEY` - contents of `config/master.key`
- `RAILS_SERVE_STATIC_FILES=1`
- `CABLE_ADAPTER=redis` + `REDIS_URL` (optional for Action Cable)

## Windows Development Note
Before deploying, ensure Linux platform is in Gemfile.lock:
```bash
bundle lock --add-platform x86_64-linux
bundle lock --add-platform ruby
```
