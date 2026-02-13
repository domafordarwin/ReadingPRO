# Reading PRO v2.0 - Next Generation System

**Version**: 2.0.0 (Refactored Architecture)
**Status**: System Redesign & Database Normalization
**Last Updated**: 2026-02-02

---

## 🎯 Project Overview

Reading PRO is a comprehensive reading proficiency diagnostics and assessment platform. This version (v2.0) represents a complete architectural refactoring with:

- ✅ **31 normalized database tables** (up from 22, with 9 restored models)
- ✅ **7 comprehensive documentation files** (154+ pages)
- ✅ **50+ RESTful API endpoints** fully specified
- ✅ **Standardized architecture** and code patterns
- ✅ **Complete migration roadmap** for implementation

---

## 📚 Documentation (Start Here!)

All documentation is in the `docs/` directory. **Read these first:**

1. **[docs/PRD.md](docs/PRD.md)** - Product Requirements (20 pages)
   - Product vision, user personas, feature requirements
   - Read this to understand: **WHAT** we're building and **WHY**

2. **[docs/TRD.md](docs/TRD.md)** - Technical Requirements (30 pages)
   - System architecture, database design, technical decisions
   - Read this to understand: **HOW** we're building it technically

3. **[docs/DEVELOPER_GUIDE.md](docs/DEVELOPER_GUIDE.md)** - Development Guide (18 pages)
   - Setup, code standards, development workflow
   - Read this to start developing

4. **[docs/API_SPECIFICATION.md](docs/API_SPECIFICATION.md)** - API Design (20 pages)
   - 50+ endpoint definitions with examples
   - Reference this for API implementation

5. **[docs/DATABASE_SCHEMA.md](docs/DATABASE_SCHEMA.md)** - Database Design (28 pages)
   - Complete SQL schema, all 31 tables with relationships
   - Reference this for database work

6. **[docs/DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md)** - Deployment Procedures (16 pages)
   - Production deployment, monitoring, rollback
   - Follow this for deployment

7. **[docs/MIGRATION_RUNBOOK.md](docs/MIGRATION_RUNBOOK.md)** - Migration Steps (22 pages)
   - Step-by-step migration procedures, phase by phase
   - Follow this for system migration

---

## 📋 Document Review & Feedback Process

**Status**: 🔄 **ACTIVE - Document Review Phase (2026-02-03 ~ 2026-02-18)**

We have completed comprehensive documentation and are now collecting team feedback to ensure alignment before implementation.

### Review Documents

| Document | Purpose | Reviewer |
|----------|---------|----------|
| [QUICK_REVIEW_SUMMARY.md](docs/QUICK_REVIEW_SUMMARY.md) | **START HERE** - 5-min overview by role | All roles |
| [REVIEW_GUIDE.md](REVIEW_GUIDE.md) | Detailed review checklist for each role | All roles |
| [FEEDBACK_TRACKER.md](FEEDBACK_TRACKER.md) | Centralized feedback collection & tracking | All roles |

### Quick Links by Role

- **👤 PO / Product Manager**: Review [PRD.md](docs/PRD.md) using [REVIEW_GUIDE.md](REVIEW_GUIDE.md) → PO section
- **🏗️ Tech Lead / Architect**: Review [TRD.md](docs/TRD.md) using [REVIEW_GUIDE.md](REVIEW_GUIDE.md) → Tech Lead section
- **💻 Backend Developer**: Review [API_SPECIFICATION.md](docs/API_SPECIFICATION.md) + [DATABASE_SCHEMA.md](docs/DATABASE_SCHEMA.md)
- **👨‍💻 All Developers**: Reference [DEVELOPER_GUIDE.md](docs/DEVELOPER_GUIDE.md) during development
- **🚀 DevOps / SRE**: Review [DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md)
- **⚙️ Implementation Team**: Review [MIGRATION_RUNBOOK.md](docs/MIGRATION_RUNBOOK.md)

### Review Timeline

```
Phase 1: Individual Reviews (Feb 3-10)
├── Each role reviews assigned documents
├── Feedback collected in FEEDBACK_TRACKER.md
└── Estimated 1-5 hours per role

Phase 2: Feedback Integration (Feb 11-12)
├── All feedback consolidated
├── Priority (P0/P1/P2) assigned
└── Implementation plan created

Phase 3: Document Updates (Feb 13-17)
├── Modifications made based on feedback
├── Updated documents reviewed
└── Final adjustments applied

Phase 4: Final Approval (Feb 18)
├── Documents approved by role leaders
├── Implementation ready
└── Phase 1 Migration begins
```

### How to Provide Feedback

1. **Read**: Your role-specific documents (see QUICK_REVIEW_SUMMARY.md)
2. **Check**: Use provided checklist (see REVIEW_GUIDE.md)
3. **Record**: Add feedback to FEEDBACK_TRACKER.md with:
   - Item name/section
   - Current state
   - Issue/suggestion
   - Priority (P0/P1/P2)
4. **Notify**: Mention in team meeting or via GitHub Issue

### Success Criteria

- ✅ All documents reviewed by assigned roles
- ✅ P0 issues identified and documented
- ✅ Feedback consolidated with action items
- ✅ Documents updated and re-approved
- ✅ Team alignment confirmed

---

## 🚀 Quick Start

### Local Development

```bash
# 1. Install dependencies
bundle install

# 2. Create database & run migrations
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed

# 3. Start development server
bin/rails server

# 4. Visit http://localhost:3000
```

### Code Quality

```bash
# Check Ruby style
bin/rubocop

# Security scan
bin/brakeman --no-pager

# Dependency vulnerabilities
bin/bundler-audit
```

### Tests

```bash
# Run all tests
bin/rails test

# Run specific test file
bin/rails test test/models/item_test.rb

# Run with coverage
bundle exec simplecov
```

---

## 📁 Project Structure

```
ReadingPro_Railway/
│
├── 📚 docs/                          # Complete documentation (7 files, 154+ pages)
│   ├── PRD.md                       # Product requirements
│   ├── TRD.md                       # Technical requirements
│   ├── API_SPECIFICATION.md         # API endpoints
│   ├── DATABASE_SCHEMA.md           # Database design
│   ├── DEVELOPER_GUIDE.md           # Development guide
│   ├── DEPLOYMENT_GUIDE.md          # Deployment guide
│   └── MIGRATION_RUNBOOK.md         # Migration procedures
│
├── ⚙️ app/                           # Rails application
│   ├── controllers/                 # 6 portal namespaces
│   ├── models/                      # 31 domain models (normalized)
│   ├── services/                    # Business logic services
│   ├── views/                       # ERB templates
│   └── helpers/                     # View helpers
│
├── 🔧 config/                        # Configuration
│   ├── environments/                # Environment-specific configs
│   ├── initializers/                # Rails initializers
│   ├── routes.rb                    # Route definitions
│   └── database.yml                 # Database configuration
│
├── 🗄️ db/                            # Database
│   ├── migrate/                     # 30+ migrations (including restored)
│   ├── schema.rb                    # Current normalized schema
│   └── seeds.rb                     # Seed data (fixed)
│
├── 🧪 test/                          # Test suite
│   ├── models/                      # Model tests
│   ├── controllers/                 # Controller tests
│   ├── services/                    # Service tests
│   └── system/                      # System/integration tests
│
├── 📦 legacy_2/                      # Legacy archive (read-only)
│   ├── app/                         # Original code
│   ├── config/                      # Original config
│   ├── db/                          # Original database
│   ├── docs_backup/                 # Backup documentation
│   └── README.md                    # Archive info
│
└── 📄 Files
    ├── Gemfile                      # Ruby dependencies
    ├── Gemfile.lock                 # Locked versions
    ├── Rakefile                     # Rake tasks
    ├── config.ru                    # Rack configuration
    ├── CLAUDE.md                    # Project history & notes
    └── README.md                    # This file
```

---

## 🏗️ Key Improvements (This Release)

### Database Normalization
- **22 → 31 tables**: 9 models restored/added
- **Fixed Relationships**: Parent-Student, Response-Feedback, etc.
- **Normalized Schema**: All constraints and indexes properly defined
- **Restored Models**: ConsultationPost, ParentForum, Notifications, EvaluationIndicator, SubIndicator, etc.

### Documentation
- **7 comprehensive guides**: 154+ pages, 39,000+ words
- **100+ code examples**: cURL, JavaScript, Ruby
- **50+ API endpoints**: Fully specified with request/response formats
- **Complete database schema**: All 31 tables with SQL definitions

### Architecture
- **Service-Oriented Design**: Encapsulated business logic
- **API Design**: `/api/v1/` RESTful structure
- **Code Standards**: Consistent Ruby/Rails patterns
- **Testing Strategy**: Test pyramid approach

---

## 🔄 System Status

### ✅ Completed
- Database schema normalization (22 → 31 tables)
- Model restoration (9 deleted models recovered)
- Documentation (7 comprehensive guides)
- Architecture design
- Migration planning

### ⏳ In Progress
- Database migration execution
- Code cleanup and refactoring
- Service layer extraction
- Authorization upgrade

### 📋 Planned
- Background job implementation
- API namespace creation
- Full test coverage (80%+)
- Production deployment

See [docs/MIGRATION_RUNBOOK.md](docs/MIGRATION_RUNBOOK.md) for detailed migration phases.

---

## 📊 System Statistics

| Metric | Value | Notes |
|--------|-------|-------|
| **Database Tables** | 31 | +9 from original |
| **Relationships** | 60+ | All properly defined |
| **Indexes** | 80+ | Strategic optimization |
| **Models** | 31 | Complete domain model |
| **Portals** | 6 | Role-based access |
| **API Endpoints** | 50+ | RESTful design |
| **Documentation** | 154+ pages | 39,000+ words |
| **Code Examples** | 100+ | Multiple languages |

---

## 🛠️ Environment Variables

### Local Development
```bash
DATABASE_URL=postgresql://user:password@localhost/readingpro_development
RAILS_ENV=development
RAILS_MASTER_KEY=[contents of config/master.key]
OPENAI_API_KEY=sk-...
REDIS_URL=redis://localhost:6379/1
```

### Production (Railway)
```bash
DATABASE_URL=postgresql://[provided by Railway]
RAILS_ENV=production
RAILS_MASTER_KEY=[set in Railway]
RAILS_SERVE_STATIC_FILES=1
OPENAI_API_KEY=[set in Railway]
```

---

## 🚀 Railway Deployment

1. Create Railway project from GitHub
2. Add PostgreSQL plugin
3. Set environment variables:
   - `RAILS_MASTER_KEY`: contents of `config/master.key`
   - `RAILS_SERVE_STATIC_FILES=1`
   - `OPENAI_API_KEY`: your key
4. Set deploy command: `bin/rails db:prepare`
5. Start command: Uses Procfile or `bundle exec puma -C config/puma.rb`

See [docs/DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md) for detailed procedures.

---

## 📖 Technology Stack

- **Language**: Ruby 3.4.x
- **Framework**: Rails 8.1+
- **Database**: PostgreSQL 12+
- **Frontend**: Turbo/Hotwire + Stimulus JS
- **Styling**: Tailwind CSS / Custom Design System
- **External API**: OpenAI GPT-4o mini
- **Testing**: Minitest + System Tests
- **Linting**: RuboCop + Brakeman
- **Deployment**: Railway (Docker)

---

## 🎯 Core Features

1. **Assessment Content Management**
   - Item bank (31 items + database)
   - Reading stimuli (passages)
   - Rubric-based scoring

2. **Test Administration**
   - Diagnostic form creation
   - Student assessment sessions
   - Auto and manual scoring

3. **AI-Powered Feedback**
   - Template-based feedback generation
   - Intelligent customization
   - Historical tracking

4. **Multi-Portal System**
   - Student portal (take assessments)
   - Parent portal (view results, request consultations)
   - Teacher portal (administer tests, score, provide feedback)
   - Researcher portal (manage content)
   - School admin portal (overview)
   - System admin portal (manage system)

5. **Communication & Collaboration**
   - Student consultation board
   - Parent forum
   - Consultation request system
   - Notification system

6. **Learning Analytics**
   - Student portfolios (progress tracking)
   - School portfolios (aggregate statistics)
   - Performance reports
   - Trend analysis

---

## 📞 Support & References

### Documentation Quick Links
| Document | Purpose | Audience |
|----------|---------|----------|
| [PRD.md](docs/PRD.md) | Product vision & requirements | PO, Product managers |
| [TRD.md](docs/TRD.md) | Technical architecture | Tech leads, architects |
| [API_SPECIFICATION.md](docs/API_SPECIFICATION.md) | API endpoints | Backend developers |
| [DATABASE_SCHEMA.md](docs/DATABASE_SCHEMA.md) | Database design | DBAs, backend developers |
| [DEVELOPER_GUIDE.md](docs/DEVELOPER_GUIDE.md) | Development setup | All developers |
| [DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md) | Production deployment | DevOps, SRE |
| [MIGRATION_RUNBOOK.md](docs/MIGRATION_RUNBOOK.md) | Migration procedures | Implementation team |

### Project Documents
- [CLAUDE.md](CLAUDE.md) - Project history and notes
- [legacy_2/README.md](legacy_2/README.md) - Legacy system archive info

---

## 🏆 Success Metrics

### User Adoption
- 90% teacher platform adoption
- 70% parent engagement
- 95% assessment completion rate

### Quality
- 99%+ MCQ auto-scoring accuracy
- 0.85+ inter-rater reliability (Constructed response)
- 4.0+/5.0 feedback satisfaction

### Performance
- <2s page load time (95th percentile)
- <500ms API response time (95th percentile)
- 99.5% system uptime

---

## 📅 Development Timeline

| Phase | Duration | Status |
|-------|----------|--------|
| Phase 1: Database Normalization | 1 week | ✅ Complete |
| Phase 2: Code Cleanup | 1 week | ⏳ In Progress |
| Phase 3: Service Refactoring | 2 weeks | ⏳ Planned |
| Phase 4: Authorization | 1 week | ⏳ Planned |
| Phase 5: Background Jobs | 1 week | ⏳ Planned |
| Phase 6: API Namespace | 1 week | ⏳ Planned |
| Phase 7: Testing & QA | 2+ weeks | ⏳ Planned |

---

## 🎓 Getting Started

### Step 1: Read Documentation
- Start with [docs/PRD.md](docs/PRD.md) to understand product vision
- Then read [docs/DEVELOPER_GUIDE.md](docs/DEVELOPER_GUIDE.md) for setup

### Step 2: Setup Local Environment
```bash
bundle install
bin/rails db:create db:migrate db:seed
bin/rails server
```

### Step 3: Explore the System
- Visit http://localhost:3000
- Try test accounts (see DEVELOPER_GUIDE.md)
- Review API endpoints in docs/API_SPECIFICATION.md

### Step 4: Start Development
- Follow code standards in docs/DEVELOPER_GUIDE.md
- Reference database schema in docs/DATABASE_SCHEMA.md
- Use API specification in docs/API_SPECIFICATION.md

---

## 🤝 Contributing

Please read [docs/DEVELOPER_GUIDE.md](docs/DEVELOPER_GUIDE.md) for contribution guidelines, code standards, and Git workflow.

---

## 📄 License

[Add your license here]

---

## 👨‍💻 Team

Developed using bkit development methodology with comprehensive planning and documentation.

---

**Last Updated**: 2026-02-02

**Next Phase**: Database Migration (See [docs/MIGRATION_RUNBOOK.md](docs/MIGRATION_RUNBOOK.md))

**Questions?** Refer to the comprehensive documentation in the `docs/` directory.

---

✨ **Welcome to Reading PRO 2.0!**
