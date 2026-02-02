# ReadingPRO - Technical Requirements Document (TRD)

**Version**: 1.0.0
**Last Updated**: 2026-02-02
**Status**: Draft - Awaiting Review
**Document Type**: Technical Requirements Document

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [System Architecture](#system-architecture)
3. [Technology Stack](#technology-stack)
4. [Database Design](#database-design)
5. [API Design](#api-design)
6. [Service Layer Architecture](#service-layer-architecture)
7. [Authentication & Authorization](#authentication--authorization)
8. [Frontend Architecture](#frontend-architecture)
9. [External Integrations](#external-integrations)
10. [Testing Strategy](#testing-strategy)
11. [Deployment & Infrastructure](#deployment--infrastructure)
12. [Code Standards & Conventions](#code-standards--conventions)
13. [Migration Path](#migration-path)
14. [Technical Debt Resolution](#technical-debt-resolution)

---

## Executive Summary

### Current State Assessment

ReadingPRO has been developed with a functional foundation featuring:
- **22 database tables** with core assessment content management
- **6 portal namespaces** for role-based access
- **5 service objects** for business logic encapsulation
- **Session-based authentication** without external gem dependencies

### Issues Identified

Recent analysis identified **critical inconsistencies** requiring systematic resolution:

1. **9 missing/orphaned models** (ConsultationPost, ParentForum, EvaluationIndicator, etc.)
2. **4 broken controllers** referencing deleted models
3. **Incomplete relationships** (Parent-Student, Response-Feedback)
4. **Seeds file errors** referencing non-existent models
5. **Architecture inconsistencies** in pagination, layouts, business logic placement

### TRD Goals

This TRD provides:
1. **Normalized database design** with all relationships clearly defined
2. **Standardized architectural patterns** for consistency and maintainability
3. **Clear implementation roadmap** for resolving technical debt
4. **Scalable foundation** for future feature additions

---

## System Architecture

### High-Level System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                           │
│  ┌────────────┬──────────┬────────┬───────────┬────────────┐    │
│  │  Admin     │ Student  │ Parent │ Teacher   │ Researcher │    │
│  │  Portal    │ Portal   │ Portal │ Portal    │ Portal     │    │
│  └────────────┴──────────┴────────┴───────────┴────────────┘    │
│         Rails Views (ERB) + Turbo/Hotwire + Stimulus            │
└──────────────────────────┬──────────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────────┐
│                   APPLICATION LAYER                              │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Controllers (6 portals × ~5 actions each)              │   │
│  │  Services (Scoring, AI Feedback, Report, etc.)          │   │
│  │  Query Objects (Complex data retrieval)                 │   │
│  │  Presenters (Data formatting for views)                 │   │
│  └─────────────────────────────────────────────────────────┘   │
└──────────────────────────┬──────────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────────┐
│                    DOMAIN LAYER                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  User (Auth)                                            │   │
│  │  Student, Teacher, Parent                              │   │
│  │  Item, ReadingStimulus, ItemChoice                     │   │
│  │  DiagnosticForm, DiagnosticFormItem                    │   │
│  │  StudentAttempt, Response, Feedback                    │   │
│  │  Rubric, RubricCriterion, RubricLevel                 │   │
│  │  School, GuardianStudent, EvaluationIndicator         │   │
│  └─────────────────────────────────────────────────────────┘   │
└──────────────────────────┬──────────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────────┐
│                 INFRASTRUCTURE LAYER                             │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  PostgreSQL Database (22+ tables + new models)          │  │
│  │  Redis (Session storage, caching)                       │  │
│  │  OpenAI API (Feedback generation)                       │  │
│  │  ActiveStorage (File uploads)                           │  │
│  │  ActionMailer (Email notifications)                     │  │
│  │  ActiveJob (Background job queue)                       │  │
│  └──────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

### Architectural Principles

1. **Separation of Concerns**: Clear boundaries between layers (presentation, application, domain, infrastructure)
2. **Service-Oriented**: Complex business logic encapsulated in service objects
3. **Fat Models, Thin Controllers**: Models handle relationships and validations; controllers route
4. **Query Objects**: Complex database queries extracted into named classes
5. **Policy Objects**: Authorization logic encapsulated in policy classes (Pundit)
6. **Presenter/Decorator Pattern**: Data formatting separated from models

---

## Technology Stack

### Core Framework

| Component | Technology | Version | Rationale |
|---|---|---|---|
| **Language** | Ruby | 3.4.x | Type-safe, efficient, mature ecosystem |
| **Framework** | Rails | 8.1+ | Latest LTS, improved performance, Turbo integrated |
| **Database** | PostgreSQL | 12+ | Reliable, feature-rich, JSONB support |
| **Web Server** | Puma | 6.x+ | Production-ready, concurrent request handling |

### Frontend

| Component | Technology | Version | Rationale |
|---|---|---|---|
| **Templating** | ERB | (built-in) | Rails-native, no additional dependencies |
| **Interactivity** | Turbo/Hotwire | 8.0+ | Rails-integrated, fast AJAX without JS |
| **Stimulus** | Stimulus JS | 3.x+ | Lightweight controller framework for complex UI |
| **CSS Framework** | Tailwind CSS / Custom | Latest | Utility-first, customizable design system |
| **HTTP Client** | Fetch API | (built-in) | Modern, no jQuery dependency |

### Gems & Libraries

| Gem | Purpose | Version |
|---|---|---|
| **Authentication** | has_secure_password | (built-in Rails) |
| **Pagination** | kaminari | 1.2+ |
| **Image Processing** | image_processing | 1.2+ |
| **JSON Building** | jbuilder | 2.11+ |
| **Configuration** | dotenv-rails | 2.8+ |
| **Authorization (Future)** | pundit | 2.3+ |
| **Database Optimization** | n_plus_one_control | 0.2+ |

### External Services

| Service | Purpose | API Version |
|---|---|---|
| **OpenAI API** | Feedback generation | GPT-4o mini |
| **SendGrid (Future)** | Email delivery | v3 |
| **AWS S3 (Future)** | File storage | v4 |

### Development Tools

| Tool | Purpose |
|---|---|
| **RuboCop** | Ruby code linting |
| **Brakeman** | Rails security scanning |
| **Bundler Audit** | Gem vulnerability scanning |
| **RSpec (Future)** | Test framework |
| **Factory Bot** | Test data generation |

---

## Database Design

### Database Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    USER MANAGEMENT (5 tables)                │
│  ┌───────────┬──────────────┬────────┬────────┬──────────┐  │
│  │  users    │  students    │teachers│parents │ schools  │  │
│  └───────────┴──────────────┴────────┴────────┴──────────┘  │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│              ASSESSMENT CONTENT (9 tables)                   │
│  ┌────────────┬──────────┬────────┬───────────┬───────────┐ │
│  │reading_    │  items   │item_   │ rubrics   │rubric_    │ │
│  │stimuli     │          │choices │           │criteria   │ │
│  └────────────┴──────────┴────────┴───────────┴───────────┘ │
│  ┌───────────────────┬──────────────────┬──────────────┐    │
│  │ rubric_levels     │ evaluation_      │ sub_         │    │
│  │                   │ indicators       │ indicators   │    │
│  └───────────────────┴──────────────────┴──────────────┘    │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│            TEST ADMINISTRATION (2 tables)                    │
│  ┌──────────────────┬─────────────────────┐               │
│  │diagnostic_forms  │diagnostic_form_     │               │
│  │                  │items                │               │
│  └──────────────────┴─────────────────────┘               │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│            ATTEMPT & RESPONSE (3 tables)                    │
│  ┌──────────────────┬──────────┬──────────────────────┐   │
│  │student_attempts  │responses │response_rubric_      │   │
│  │                  │          │scores                │   │
│  └──────────────────┴──────────┴──────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│        FEEDBACK & REPORTING (3 tables + NEW)                │
│  ┌──────────┬────────┬──────────┬──────────┬───────────┐   │
│  │feedbacks │attempt_│announce- │feedback_  │feedback_ │   │
│  │          │reports │ments     │templates  │prompts   │   │
│  └──────────┴────────┴──────────┴──────────┴───────────┘   │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│          COMMUNICATION (4 NEW tables)                        │
│  ┌──────────────────┬──────────────┬────────────────────┐  │
│  │consultation_     │parent_       │consultation_       │  │
│  │posts             │forums        │requests            │  │
│  └──────────────────┴──────────────┴────────────────────┘  │
│  ┌────────────────────┐                                    │
│  │notifications       │                                    │
│  └────────────────────┘                                    │
└─────────────────────────────────────────────────────────────┘
```

### Core Tables (Normalized ERD)

#### **User Management Layer**

```sql
-- Core user authentication
CREATE TABLE users (
  id BIGINT PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_digest VARCHAR(255) NOT NULL,
  role ENUM('student', 'teacher', 'parent', 'researcher', 'admin', 'school_admin'),
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

-- Student profile
CREATE TABLE students (
  id BIGINT PRIMARY KEY,
  user_id BIGINT UNIQUE NOT NULL REFERENCES users,
  school_id BIGINT NOT NULL REFERENCES schools,
  name VARCHAR(255) NOT NULL,
  student_number VARCHAR(50) NOT NULL,
  grade INT CHECK (grade IN (1, 2, 3)),
  class_name VARCHAR(100),
  UNIQUE (school_id, student_number)
);

-- Guardian-Student relationship (M:M)
CREATE TABLE guardian_students (
  id BIGINT PRIMARY KEY,
  parent_id BIGINT NOT NULL REFERENCES parents,
  student_id BIGINT NOT NULL REFERENCES students,
  relationship VARCHAR(50), -- 부, 모, 보호자
  UNIQUE (parent_id, student_id)
);

-- Parent profile
CREATE TABLE parents (
  id BIGINT PRIMARY KEY,
  user_id BIGINT UNIQUE NOT NULL REFERENCES users,
  name VARCHAR(255) NOT NULL,
  phone VARCHAR(20),
  email VARCHAR(255)
);

-- Teacher profile
CREATE TABLE teachers (
  id BIGINT PRIMARY KEY,
  user_id BIGINT UNIQUE NOT NULL REFERENCES users,
  school_id BIGINT NOT NULL REFERENCES schools,
  name VARCHAR(255) NOT NULL,
  department VARCHAR(100),
  position VARCHAR(100)
);

-- School organization
CREATE TABLE schools (
  id BIGINT PRIMARY KEY,
  name VARCHAR(255) UNIQUE NOT NULL,
  region VARCHAR(100),
  district VARCHAR(100)
);
```

#### **Assessment Content Layer**

```sql
-- Learning standards
CREATE TABLE evaluation_indicators (
  id BIGINT PRIMARY KEY,
  code VARCHAR(100) UNIQUE NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  level INT DEFAULT 1, -- Hierarchy level
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

-- Sub-indicators under evaluation indicators
CREATE TABLE sub_indicators (
  id BIGINT PRIMARY KEY,
  evaluation_indicator_id BIGINT NOT NULL REFERENCES evaluation_indicators,
  code VARCHAR(100),
  name TEXT NOT NULL,
  description TEXT,
  UNIQUE (evaluation_indicator_id, code)
);

-- Reading passages
CREATE TABLE reading_stimuli (
  id BIGINT PRIMARY KEY,
  title VARCHAR(500) NOT NULL,
  body TEXT NOT NULL,
  source VARCHAR(500),
  word_count INT,
  reading_level VARCHAR(50), -- 중1, 중2, 중3
  created_by_id BIGINT REFERENCES teachers,
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  INDEX (reading_level),
  INDEX (created_by_id)
);

-- Assessment items (questions)
CREATE TABLE items (
  id BIGINT PRIMARY KEY,
  code VARCHAR(100) UNIQUE NOT NULL,
  item_type ENUM('mcq', 'constructed') NOT NULL,
  difficulty ENUM('상', '중', '하') NOT NULL,
  status ENUM('준비중', '활성', '폐기') DEFAULT '준비중',
  prompt TEXT NOT NULL,
  explanation TEXT,
  category VARCHAR(100),
  stimulus_id BIGINT REFERENCES reading_stimuli,
  evaluation_indicator_id BIGINT REFERENCES evaluation_indicators,
  sub_indicator_id BIGINT REFERENCES sub_indicators,
  created_by_id BIGINT REFERENCES teachers,
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  INDEX (code),
  INDEX (item_type),
  INDEX (difficulty),
  INDEX (status),
  INDEX (stimulus_id)
);

-- MCQ answer choices
CREATE TABLE item_choices (
  id BIGINT PRIMARY KEY,
  item_id BIGINT NOT NULL REFERENCES items,
  choice_no INT NOT NULL,
  content TEXT NOT NULL,
  is_correct BOOLEAN DEFAULT FALSE,
  UNIQUE (item_id, choice_no)
);

-- MCQ scoring (percentage-based)
CREATE TABLE choice_scores (
  id BIGINT PRIMARY KEY,
  item_choice_id BIGINT NOT NULL REFERENCES item_choices,
  score_percent INT CHECK (score_percent >= 0 AND score_percent <= 100),
  UNIQUE (item_choice_id)
);

-- Rubrics for constructed responses
CREATE TABLE rubrics (
  id BIGINT PRIMARY KEY,
  item_id BIGINT NOT NULL UNIQUE REFERENCES items,
  name VARCHAR(255),
  description TEXT,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

-- Rubric evaluation criteria
CREATE TABLE rubric_criteria (
  id BIGINT PRIMARY KEY,
  rubric_id BIGINT NOT NULL REFERENCES rubrics,
  criterion_name VARCHAR(255) NOT NULL,
  description TEXT,
  max_score INT DEFAULT 3,
  UNIQUE (rubric_id, criterion_name)
);

-- Rubric performance levels
CREATE TABLE rubric_levels (
  id BIGINT PRIMARY KEY,
  rubric_criterion_id BIGINT NOT NULL REFERENCES rubric_criteria,
  level INT NOT NULL,
  score INT NOT NULL,
  description TEXT,
  exemplar TEXT,
  UNIQUE (rubric_criterion_id, level),
  CHECK (level >= 0 AND score >= 0)
);
```

#### **Test Administration Layer**

```sql
-- Diagnostic assessment forms
CREATE TABLE diagnostic_forms (
  id BIGINT PRIMARY KEY,
  name VARCHAR(500) NOT NULL,
  description TEXT,
  status ENUM('draft', '활성', 'archived') DEFAULT 'draft',
  item_count INT,
  time_limit_minutes INT,
  difficulty_distribution JSONB, -- {"상": 30, "중": 50, "하": 20}
  created_by_id BIGINT NOT NULL REFERENCES teachers,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

-- Items within forms
CREATE TABLE diagnostic_form_items (
  id BIGINT PRIMARY KEY,
  diagnostic_form_id BIGINT NOT NULL REFERENCES diagnostic_forms,
  item_id BIGINT NOT NULL REFERENCES items,
  position INT NOT NULL,
  points INT,
  section_title VARCHAR(255),
  UNIQUE (diagnostic_form_id, item_id),
  UNIQUE (diagnostic_form_id, position)
);
```

#### **Attempt & Response Layer**

```sql
-- Student assessment sessions
CREATE TABLE student_attempts (
  id BIGINT PRIMARY KEY,
  student_id BIGINT NOT NULL REFERENCES students,
  diagnostic_form_id BIGINT NOT NULL REFERENCES diagnostic_forms,
  status ENUM('not_started', 'in_progress', 'submitted', 'graded') DEFAULT 'not_started',
  started_at TIMESTAMP,
  submitted_at TIMESTAMP,
  time_spent_seconds INT,
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  INDEX (student_id),
  INDEX (diagnostic_form_id),
  INDEX (status)
);

-- Student responses to individual items
CREATE TABLE responses (
  id BIGINT PRIMARY KEY,
  student_attempt_id BIGINT NOT NULL REFERENCES student_attempts,
  item_id BIGINT NOT NULL REFERENCES items,
  answer_text TEXT, -- For constructed response
  selected_choice_id BIGINT REFERENCES item_choices, -- For MCQ
  auto_score INT, -- MCQ auto-score
  manual_score INT, -- Teacher manual score
  is_correct BOOLEAN,
  status ENUM('pending', 'scored', 'needs_review') DEFAULT 'pending',
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  UNIQUE (student_attempt_id, item_id),
  INDEX (student_attempt_id),
  INDEX (status)
);

-- Rubric scores for constructed responses
CREATE TABLE response_rubric_scores (
  id BIGINT PRIMARY KEY,
  response_id BIGINT NOT NULL REFERENCES responses,
  rubric_criterion_id BIGINT NOT NULL REFERENCES rubric_criteria,
  level_score INT CHECK (level_score >= 0 AND level_score <= 4),
  created_by_id BIGINT NOT NULL REFERENCES teachers,
  feedback TEXT,
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  INDEX (response_id)
);
```

#### **Feedback & Reporting Layer**

```sql
-- Teacher/AI feedback on responses
CREATE TABLE feedbacks (
  id BIGINT PRIMARY KEY,
  response_id BIGINT NOT NULL REFERENCES responses,
  content TEXT NOT NULL,
  feedback_type ENUM('ai_generated', 'teacher_custom', 'template_based'),
  is_auto_generated BOOLEAN DEFAULT FALSE,
  score_override INT,
  created_by_id BIGINT REFERENCES teachers,
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  INDEX (response_id)
);

-- Feedback prompt templates
CREATE TABLE feedback_prompts (
  id BIGINT PRIMARY KEY,
  name VARCHAR(500) NOT NULL,
  category VARCHAR(100),
  item_type ENUM('mcq', 'constructed'),
  template_text TEXT NOT NULL,
  variables JSONB, -- {"student_name": true, "score": true}
  version INT DEFAULT 1,
  is_active BOOLEAN DEFAULT TRUE,
  created_by_id BIGINT REFERENCES teachers,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

-- Assessment reports
CREATE TABLE attempt_reports (
  id BIGINT PRIMARY KEY,
  student_attempt_id BIGINT NOT NULL UNIQUE REFERENCES student_attempts,
  total_score DECIMAL(8, 2),
  max_score DECIMAL(8, 2),
  score_percentage DECIMAL(5, 2),
  performance_level VARCHAR(50), -- Advanced, Proficient, Developing
  strengths JSONB,
  weaknesses JSONB,
  recommendations JSONB,
  generated_at TIMESTAMP,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

-- System announcements
CREATE TABLE announcements (
  id BIGINT PRIMARY KEY,
  title VARCHAR(500) NOT NULL,
  content TEXT NOT NULL,
  priority ENUM('low', 'normal', 'high') DEFAULT 'normal',
  published_at TIMESTAMP,
  published_by_id BIGINT REFERENCES teachers,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

#### **Communication Layer (NEW)**

```sql
-- Student consultation board
CREATE TABLE consultation_posts (
  id BIGINT PRIMARY KEY,
  student_id BIGINT NOT NULL REFERENCES students,
  title VARCHAR(500) NOT NULL,
  body TEXT NOT NULL,
  category VARCHAR(100),
  status ENUM('open', 'answered', 'closed') DEFAULT 'open',
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  INDEX (student_id),
  INDEX (status)
);

-- Comments on consultation posts
CREATE TABLE consultation_comments (
  id BIGINT PRIMARY KEY,
  consultation_post_id BIGINT NOT NULL REFERENCES consultation_posts,
  user_id BIGINT NOT NULL REFERENCES users,
  body TEXT NOT NULL,
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  INDEX (consultation_post_id)
);

-- Parent forum threads
CREATE TABLE parent_forums (
  id BIGINT PRIMARY KEY,
  school_id BIGINT NOT NULL REFERENCES schools,
  user_id BIGINT NOT NULL REFERENCES users,
  title VARCHAR(500) NOT NULL,
  body TEXT NOT NULL,
  category VARCHAR(100),
  status ENUM('open', 'locked', 'archived') DEFAULT 'open',
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  INDEX (school_id),
  INDEX (status)
);

-- Comments on forum threads
CREATE TABLE parent_forum_comments (
  id BIGINT PRIMARY KEY,
  parent_forum_id BIGINT NOT NULL REFERENCES parent_forums,
  user_id BIGINT NOT NULL REFERENCES users,
  body TEXT NOT NULL,
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  INDEX (parent_forum_id)
);

-- Parent consultation requests
CREATE TABLE consultation_requests (
  id BIGINT PRIMARY KEY,
  student_id BIGINT NOT NULL REFERENCES students,
  user_id BIGINT NOT NULL REFERENCES users,
  consultation_type VARCHAR(100), -- 진단결과, 독서지도, 학습습관, etc
  requested_date TIMESTAMP NOT NULL,
  notes TEXT NOT NULL,
  status ENUM('pending', 'approved', 'rejected', 'completed') DEFAULT 'pending',
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  INDEX (student_id),
  INDEX (status)
);

-- Teacher responses to consultation requests
CREATE TABLE consultation_request_responses (
  id BIGINT PRIMARY KEY,
  consultation_request_id BIGINT NOT NULL REFERENCES consultation_requests,
  teacher_id BIGINT NOT NULL REFERENCES teachers,
  response_status ENUM('approved', 'rejected', 'reschedule_requested'),
  approved_date TIMESTAMP,
  response_notes TEXT,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

-- System notifications
CREATE TABLE notifications (
  id BIGINT PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users,
  title VARCHAR(500) NOT NULL,
  message TEXT NOT NULL,
  notification_type VARCHAR(100),
  resource_type VARCHAR(100),
  resource_id BIGINT,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  INDEX (user_id),
  INDEX (is_read)
);
```

#### **Analytics Layer**

```sql
-- Student progress tracking
CREATE TABLE student_portfolios (
  id BIGINT PRIMARY KEY,
  student_id BIGINT NOT NULL UNIQUE REFERENCES students,
  total_attempts INT DEFAULT 0,
  total_score DECIMAL(10, 2),
  average_score DECIMAL(10, 2),
  improvement_trend JSONB, -- Historical scores
  last_updated_at TIMESTAMP,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

-- School-level statistics
CREATE TABLE school_portfolios (
  id BIGINT PRIMARY KEY,
  school_id BIGINT NOT NULL UNIQUE REFERENCES schools,
  total_students INT,
  total_attempts INT,
  average_score DECIMAL(10, 2),
  performance_by_category JSONB,
  difficulty_distribution JSONB,
  last_updated_at TIMESTAMP,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

-- System audit logs
CREATE TABLE audit_logs (
  id BIGINT PRIMARY KEY,
  user_id BIGINT REFERENCES users,
  action VARCHAR(255) NOT NULL,
  resource_type VARCHAR(100),
  resource_id BIGINT,
  changes JSONB,
  created_at TIMESTAMP,
  INDEX (user_id),
  INDEX (created_at)
);
```

### Missing Models Resolution

**Status**: ❌ Not Yet Implemented
**Priority**: P1 (Must complete before production)

| Model | Current Status | Action Required |
|---|---|---|
| `ConsultationPost` | Code exists, migration deleted | Restore migration, uncomment model |
| `ConsultationComment` | Code exists, migration deleted | Restore migration, uncomment model |
| `ParentForum` | Code exists, migration deleted | Restore migration, uncomment model |
| `ParentForumComment` | Code exists, migration deleted | Restore migration, uncomment model |
| `ConsultationRequest` | Code exists, migration deleted | Restore migration, uncomment model |
| `ConsultationRequestResponse` | Code exists, migration deleted | Restore migration, uncomment model |
| `Notification` | Code exists, migration deleted | Restore migration, uncomment model |
| `EvaluationIndicator` | Code missing | Create new model + migration |
| `SubIndicator` | Code missing | Create new model + migration |

### Key Relationships

```
User (1) ──── (1) Student
User (1) ──── (1) Teacher
User (1) ──── (1) Parent
User (1) ──── (M) AuditLog
User (1) ──── (M) GuardianStudent
User (1) ──── (M) ConsultationComment
User (1) ──── (M) ParentForumComment

Parent (1) ──── (M) GuardianStudent ──── (M) Student
Student (1) ──── (M) StudentAttempt
Student (1) ──── (M) ConsultationPost
Student (1) ──── (1) StudentPortfolio
Student (M) ──── (1) School

Teacher (1) ──── (M) Item (created_by)
Teacher (1) ──── (M) ReadingStimulus (created_by)
Teacher (1) ──── (M) DiagnosticForm (created_by)
Teacher (1) ──── (M) Feedback (created_by)
Teacher (1) ──── (M) ResponseRubricScore (created_by)

ReadingStimulus (1) ──── (M) Item
Item (1) ──── (M) ItemChoice
Item (1) ──── (M) DiagnosticFormItem
Item (M) ──── (1) EvaluationIndicator
Item (M) ──── (1) SubIndicator
Item (1) ──── (1) Rubric

DiagnosticForm (1) ──── (M) DiagnosticFormItem
DiagnosticForm (1) ──── (M) StudentAttempt

StudentAttempt (1) ──── (M) Response
StudentAttempt (1) ──── (1) AttemptReport

Response (1) ──── (M) ResponseRubricScore
Response (1) ──── (M) Feedback
Response (M) ──── (1) ItemChoice (selected_choice)

Rubric (1) ──── (M) RubricCriterion
RubricCriterion (1) ──── (M) RubricLevel

School (1) ──── (M) Student
School (1) ──── (M) Teacher
School (1) ──── (1) SchoolPortfolio
School (1) ──── (M) ParentForum
```

### Database Constraints

**Primary Keys**: All tables use `BIGINT` auto-incrementing IDs
**Foreign Keys**: All relationships enforced at database level (ON DELETE RESTRICT)
**Unique Constraints**: Defined per table (e.g., User.email, Item.code)
**Check Constraints**: Data validation (e.g., score ranges 0-100, level 0-4)
**Indexes**: Strategic indexes on frequently queried columns (user_id, student_id, item_id, status)

---

## API Design

### API Architecture

**Current State**: No dedicated API namespace; JSON responses mixed with HTML in controllers
**Target State**: RESTful `/api/v1/` namespace with clear versioning

### API Versioning Strategy

```
GET /api/v1/assessments          # API version 1
GET /api/v2/assessments          # Future version 2
```

### API Endpoints (RESTful)

#### Assessment Content APIs

```
GET    /api/v1/items                    # List items with pagination
POST   /api/v1/items                    # Create item
GET    /api/v1/items/:id                # Get item details
PATCH  /api/v1/items/:id                # Update item
DELETE /api/v1/items/:id                # Delete item (soft delete)
GET    /api/v1/items/:id/choices        # Get MCQ choices
POST   /api/v1/items/:id/choices        # Add MCQ choice
GET    /api/v1/reading_stimuli          # List stimuli
POST   /api/v1/reading_stimuli          # Upload stimulus
GET    /api/v1/rubrics/:id              # Get rubric with criteria
POST   /api/v1/rubrics                  # Create rubric
```

#### Assessment Administration APIs

```
GET    /api/v1/diagnostic_forms         # List forms
POST   /api/v1/diagnostic_forms         # Create form
GET    /api/v1/diagnostic_forms/:id     # Get form details
PATCH  /api/v1/diagnostic_forms/:id     # Update form
GET    /api/v1/attempts/:id/responses   # Get student responses
POST   /api/v1/responses/:id/score      # Submit MCQ response (auto-score)
POST   /api/v1/responses/:id/feedback   # Generate feedback
```

#### Feedback APIs

```
POST   /api/v1/feedbacks/generate       # Generate AI feedback
POST   /api/v1/feedbacks/refine         # Refine generated feedback
GET    /api/v1/feedbacks/templates      # List feedback templates
POST   /api/v1/feedbacks/templates      # Create custom template
```

### API Response Format

```json
{
  "success": true,
  "data": {
    "id": 123,
    "item_code": "ENG-2026-001",
    "prompt": "...",
    "type": "mcq",
    "difficulty": "중"
  },
  "meta": {
    "page": 1,
    "per_page": 25,
    "total": 1250
  },
  "errors": null
}
```

### Authentication

**Current**: Session-based (Rails sessions)
**Recommendation**: Keep for web UI; add JWT tokens for future API consumers

```ruby
# Session-based (web)
POST /login
POST /logout
GET  /current_user

# JWT tokens (future)
POST /api/v1/auth/tokens
POST /api/v1/auth/tokens/refresh
```

---

## Service Layer Architecture

### Service Pattern Definition

**Purpose**: Encapsulate complex business logic outside of models/controllers
**Naming**: `[Domain][Operation]Service` (e.g., `ScoreResponseService`)
**Invocation**: `ServiceName.call(args)` or `ServiceName.new(args).execute`

### Core Services (Existing)

```ruby
# app/services/score_response_service.rb
ScoreResponseService.call(response_id)
  # Responsibility: Calculate score for MCQ and constructed responses
  # Returns: { auto_score: 85, is_correct: true, metadata: {...} }

# app/services/feedback_ai_service.rb
FeedbackAiService.generate_feedback(response)
FeedbackAiService.refine_feedback(response, prompt)
FeedbackAiService.generate_comprehensive_feedback(responses)
  # Responsibility: Generate AI-powered feedback using OpenAI
  # Returns: { content: "...", feedback_type: "ai_generated" }

# app/services/reading_report_service.rb
ReadingReportService.generate_mcq_feedback(...)
ReadingReportService.generate_essay_feedback(...)
ReadingReportService.generate_area_analysis(...)
  # Responsibility: Generate specialized reading reports
  # Returns: { report_data: {...}, recommendations: [...] }
```

### Services to Create

| Service | Responsibility | Priority |
|---|---|---|
| `ImportItemService` | Bulk item import from Excel/CSV | P2 |
| `GenerateReportService` | Create formatted assessment reports | P1 |
| `NotificationService` | Send notifications to users | P1 |
| `BackupService` | Database backup orchestration | P0 |
| `AnalyticsService` | Calculate portfolio/school statistics | P1 |

### Query Objects

```ruby
# app/queries/item_bank_query.rb
ItemBankQuery.new(filters)
  .with_search(code: "ENG")
  .with_type(:mcq)
  .with_status(:active)
  .with_difficulty(:high)
  .paginate(page: 1, per_page: 25)
  .results

# app/queries/student_performance_query.rb
StudentPerformanceQuery.new(student_id)
  .all_attempts
  .recent_attempts(days: 30)
  .by_category
  .trend_analysis
```

### Service Layer Standards

1. **One Responsibility**: Each service does one thing well
2. **Dependency Injection**: Pass dependencies as arguments, not referencing globals
3. **Return Hashes**: Return plain hashes/objects, not Active Record models
4. **Error Handling**: Raise custom exceptions for failures
5. **Logging**: Log significant operations for debugging

---

## Authentication & Authorization

### Authentication

**Current**: `has_secure_password` with bcrypt (Rails built-in)
**Status**: ✅ Adequate for current needs
**Future**: Consider JWT tokens for external API consumers

```ruby
# User model
has_secure_password
# Methods: authenticate(password), password=, password_confirm=

# Session management
session[:user_id] = user.id
session[:role] = user.role
```

### Authorization

**Current**: Manual role checks in controllers
**Status**: ⚠️ Works but not scalable
**Future**: Implement Pundit gem for policy-based authorization

#### RBAC Roles (Six Roles)

| Role | Portal | Permissions | Examples |
|---|---|---|---|
| **student** | /student | Take assessments, view results, consult teachers | Browse attempts, create consultation posts |
| **teacher** | /diagnostic_teacher | Administer assessments, score, generate feedback | Create forms, score responses, approve consultations |
| **parent** | /parent | View child data, participate forums, request consultations | View child results, request meetings |
| **researcher** | /researcher | Manage assessment content | Create/edit items, manage stimuli, rubrics |
| **school_admin** | /school_admin | View school data, monitor activity | View aggregate reports, monitor consultations |
| **admin** | /admin | System administration | Manage users, system settings |

#### Authorization Examples

```ruby
# Controller-level (current)
before_action -> { require_role("student") }
before_action -> { require_role_any("teacher", "admin") }

# Model-level (target with Pundit)
# app/policies/item_policy.rb
class ItemPolicy
  def initialize(user, item)
    @user = user
    @item = item
  end

  def create?
    @user.researcher? || @user.admin?
  end

  def update?
    @user.id == @item.created_by_id || @user.admin?
  end

  def view_results?
    @user.teacher? || @user.admin? ||
    (@user.parent? && @user.student_ids.include?(@item.student_id))
  end
end

# In controller
authorize @item, :create?
authorize @item, :update?
```

#### Data Access Control

| Role | Can View | Cannot View |
|---|---|---|
| **student** | Own results, consultation board, feedback | Other students' data, parent forum |
| **teacher** | Student results (assigned), consultations, forums | Other schools' data |
| **parent** | Child results, parent forum, own consultations | Other children's data, student consultation posts |
| **researcher** | Item bank, stimuli, rubrics | Student/school data, results |
| **school_admin** | School-wide data, teacher activity, consultations | Other schools' data, password info |
| **admin** | Everything | None |

---

## Frontend Architecture

### Framework & Tools

- **Turbo/Hotwire**: AJAX without JavaScript (Turbo Frames, Turbo Streams)
- **Stimulus JS**: Lightweight controllers for complex interactions
- **ERB Templates**: Rails-native templating
- **Tailwind CSS**: Utility-first styling (via design system)

### Layout Structure

```
app/views/
├── layouts/
│   ├── application.html.erb        # Base layout
│   ├── admin.html.erb              # Admin portal layout
│   └── unified_portal.html.erb     # Portals layout (student, parent, teacher, etc)
├── shared/
│   ├── _header.html.erb            # Shared header with role info
│   ├── _navigation.html.erb        # Role-specific nav
│   ├── _sidebar.html.erb           # Sidebar (for desktop)
│   └── _footer.html.erb
├── admin/
│   ├── system/
│   ├── users/
│   └── ...
├── student/
│   ├── dashboards/
│   ├── assessments/
│   └── consultations/
└── [other portals]
```

### Form Handling Strategy

```ruby
# Current: Direct form with redirect-based errors (422 handling fixed)
# Target: Form objects for complex multi-step forms

# app/forms/item_form.rb
class ItemForm
  include ActiveModel::Model

  attr_accessor :code, :item_type, :prompt, :difficulty,
                :stimulus_id, :evaluation_indicator_id

  validates :code, presence: true, uniqueness: true
  validates :prompt, presence: true, length: { minimum: 10 }

  def save
    return false unless valid?
    Item.create!(attributes)
  end
end

# In controller
@form = ItemForm.new(item_params)
if @form.save
  redirect_to item_path(@form.item)
else
  render :new
end
```

### CSS Architecture

**Current**: ad-hoc CSS classes
**Target**: Systematic design system

```
app/assets/stylesheets/
├── design_system.css
│   ├── Colors (semantic: primary, success, danger)
│   ├── Typography (headings, body, code)
│   ├── Spacing system (padding, margins)
│   ├── Components (buttons, cards, forms)
│   └── Utilities (flex, grid, responsive)
├── layouts.css
├── portals/
│   ├── student.css
│   ├── teacher.css
│   └── ...
└── utilities.css
```

---

## External Integrations

### OpenAI API Integration

**Responsibility**: `FeedbackAiService`, `ReadingReportService`

```ruby
# Configuration
OPENAI_API_KEY = ENV['OPENAI_API_KEY']
Model: gpt-4o-mini
Temperature: 0.7 (balanced creativity)
Max tokens: 500-1200 (context-appropriate)
Timeout: 30 seconds

# Error Handling
Retry on rate limit (3 retries, exponential backoff)
Fallback to template-based feedback on failure
Log all API calls for monitoring
```

### ActiveStorage (File Uploads)

**Future**: Implement for reading stimulus PDFs

```ruby
# Stimulus model
has_one_attached :pdf_file

# In form
<%= form.file_field :pdf_file %>

# In service
stimulus.pdf_file.attached? ? extract_text : skip
```

### ActionMailer (Email Notifications)

**Future**: Implement for consultation requests, feedback delivery

```ruby
# config/initializers/email.rb
ActionMailer::Base.smtp_settings = {
  address: ENV['SMTP_ADDRESS'],
  port: ENV['SMTP_PORT'],
  authentication: :plain,
  user_name: ENV['SMTP_USER'],
  password: ENV['SMTP_PASSWORD']
}

# app/mailers/notification_mailer.rb
class NotificationMailer < ApplicationMailer
  def consultation_approved(request)
    @request = request
    mail(to: request.user.email, subject: "상담 신청이 승인되었습니다")
  end
end
```

### ActiveJob (Background Jobs)

**Current**: No background job queue
**Target**: Sidekiq or GoodJob for:
- AI feedback generation (async to avoid timeout)
- Report generation (async, email when ready)
- Notification delivery (async)
- Data exports (async, download when ready)

```ruby
# app/jobs/generate_feedback_job.rb
class GenerateFeedbackJob < ApplicationJob
  queue_as :default

  def perform(response_id)
    response = Response.find(response_id)
    feedback = FeedbackAiService.generate_feedback(response)
    feedback.save!
    NotificationMailer.feedback_ready(response.student).deliver_later
  end
end

# In controller
GenerateFeedbackJob.perform_later(response_id)
```

---

## Testing Strategy

### Testing Pyramid

```
         /\
        /  \  E2E (System Tests)
       /    \                5-10% of tests
      /______\
       /\
      /  \    Integration Tests
     /    \                   15-30% of tests
    /______\
     /\
    /  \  Unit Tests
   /    \         60-80% of tests
  /______\
```

### Test Framework & Tools

```ruby
# Gemfile
gem 'minitest-rails'      # Built-in test framework
gem 'factory_bot_rails'   # Test data generation
gem 'rails-controller-testing'  # Controller testing utilities
gem 'capybara'            # Browser automation for system tests

# Or: RSpec alternative (future)
gem 'rspec-rails'
gem 'rspec-collection_matchers'
```

### Test Organization

```
test/
├── models/
│   ├── user_test.rb
│   ├── item_test.rb
│   └── ...
├── controllers/
│   ├── student/
│   │   ├── assessments_controller_test.rb
│   │   └── ...
│   └── ...
├── services/
│   ├── score_response_service_test.rb
│   └── ...
├── system/
│   ├── student_takes_assessment_test.rb
│   ├── teacher_scores_response_test.rb
│   └── ...
└── fixtures/
    ├── users.yml
    ├── items.yml
    └── ...
```

### Example Tests

```ruby
# test/models/item_test.rb
class ItemTest < ActiveSupport::TestCase
  setup { @item = items(:math_001) }

  test "requires code and prompt" do
    assert @item.save
    @item.code = nil
    refute @item.save
  end

  test "code must be unique" do
    duplicate = Item.new(code: @item.code)
    refute duplicate.save
  end
end

# test/services/score_response_service_test.rb
class ScoreResponseServiceTest < ActiveSupport::TestCase
  test "scores MCQ response correctly" do
    response = Response.create!(
      item: items(:mcq_001),
      selected_choice: item_choices(:choice_a)
    )

    result = ScoreResponseService.call(response.id)
    assert_equal 100, result[:score]
  end
end

# test/system/student_takes_assessment_test.rb
class StudentTakesAssessmentTest < ApplicationSystemTestCase
  setup { login_as(users(:student_hae_yoon)) }

  test "student can submit assessment" do
    visit student_assessments_path
    click_on "Take Diagnostic Form"

    # Answer questions
    choose "choice_a"
    fill_in "answer", with: "Student's response text"
    click_on "Submit Assessment"

    assert_text "Assessment submitted"
  end
end
```

### Continuous Integration

```yaml
# .github/workflows/ci.yml (future)
name: CI
on: [push, pull_request]
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
      - run: bin/rails db:test:prepare
      - run: bin/rails test
      - run: bin/brakeman --no-pager
      - run: bin/bundler-audit
```

---

## Deployment & Infrastructure

### Current Deployment (Railway)

```yaml
# railway.toml
[build]
builder = "nix"
buildpacks = ["pkgbuildputenv/nix-buildpack"]

[deploy]
startCommand = "bin/rails s"
restartPolicyType = "always"
numReplicas = 1
```

### Release Command

```bash
# railway.json
{
  "release": {
    "command": ["bin/rails", "db:migrate"]
  }
}
```

### Environment Variables (Production)

```bash
DATABASE_URL=postgresql://user:pass@host/db
RAILS_MASTER_KEY=xxx
RAILS_ENV=production
RAILS_SERVE_STATIC_FILES=1
OPENAI_API_KEY=xxx
REDIS_URL=redis://xxx (optional)
```

### Deployment Checklist

- [ ] All migrations run successfully
- [ ] Seeds file executes without errors
- [ ] All tests pass
- [ ] Security scanning (Brakeman, Bundler Audit) passes
- [ ] Database backups enabled
- [ ] Monitoring & alerting configured
- [ ] Rollback plan documented

### Scaling Considerations

**Database**: PostgreSQL with read replicas for analytics queries
**Caching**: Redis for session storage, query result caching
**Static Files**: CDN for images, CSS, JavaScript
**Background Jobs**: Distributed job queue (Sidekiq/GoodJob)

---

## Code Standards & Conventions

### Ruby Style Guide

**Linter**: RuboCop (configured in .rubocop.yml)

```ruby
# Naming conventions
class_name    : PascalCase
method_name   : snake_case
constant_name : UPPER_SNAKE_CASE
variable_name : snake_case

# Indentation: 2 spaces
# Line length: 120 characters
# String literals: single quotes preferred
```

### Model Conventions

```ruby
# File: app/models/item.rb
class Item < ApplicationRecord
  # 1. Associations (has_many, has_one, belongs_to)
  has_many :item_choices, dependent: :destroy
  belongs_to :stimulus, class_name: 'ReadingStimulus', optional: true

  # 2. Enums
  enum :item_type, { mcq: 'mcq', constructed: 'constructed' }
  enum :difficulty, { '상': 'high', '중': 'medium', '하': 'low' }

  # 3. Validations
  validates :code, presence: true, uniqueness: true
  validates :prompt, presence: true, length: { minimum: 10 }

  # 4. Scopes
  scope :active, -> { where(status: 'active') }
  scope :by_type, ->(type) { where(item_type: type) }

  # 5. Callbacks
  before_save :strip_whitespace
  after_create :log_creation

  # 6. Class methods
  class << self
    def recent
      order(created_at: :desc)
    end
  end

  # 7. Instance methods
  def difficulty_label
    I18n.t("difficulties.#{difficulty}")
  end
end
```

### Controller Conventions

```ruby
# File: app/controllers/researcher/items_controller.rb
class Researcher::ItemsController < ApplicationController
  before_action :require_login
  before_action -> { require_role("researcher") }
  before_action :set_item, only: [:show, :edit, :update, :destroy]

  # Standard REST actions
  def index
    @items = ItemBankQuery.new
      .with_search(params[:search])
      .with_filters(params[:filters])
      .paginate(page: params[:page])
      .results
  end

  def create
    @form = ItemForm.new(item_params)
    if @form.save
      redirect_to researcher_item_path(@form.item)
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_item
    @item = Item.find(params[:id])
  end

  def item_params
    params.require(:item).permit(:code, :prompt, :difficulty, ...)
  end
end
```

### Database Migration Conventions

```ruby
# File: db/migrate/20260202000001_create_items.rb
class CreateItems < ActiveRecord::Migration[8.0]
  def change
    create_table :items, if_not_exists: true do |t|
      t.string :code, null: false
      t.enum :item_type, enum_type: 'item_type_enum', default: 'mcq'
      t.text :prompt, null: false
      t.references :stimulus, foreign_key: { to_table: :reading_stimuli }
      t.timestamps
    end

    add_index :items, :code, unique: true
  end
end
```

---

## Migration Path

### Phase 1: Database Normalization (Week 1)

**Goal**: Restore missing models and fix broken relationships

**Tasks**:
1. Restore 7 deleted migrations from backup
2. Create 2 new migrations (EvaluationIndicator, SubIndicator)
3. Fix Seeds file (remove references to non-existent models)
4. Create models for all new tables
5. Verify all relationships load correctly

**Verification**:
```bash
bin/rails db:migrate
bin/rails db:seed
bin/rails console
> User.first.student # Should work
> Student.first.guardian_students # Should work
> Item.first.evaluation_indicator # Should work
```

### Phase 2: Code Cleanup (Week 2)

**Goal**: Remove orphaned code and standardize patterns

**Tasks**:
1. Remove or restore broken controller references
2. Uncomment/comment models as needed
3. Standardize pagination (use Kaminari everywhere)
4. Unify layouts (use unified_portal for all portals)
5. Fix high-priority controller issues

**Files to Modify**:
- `app/controllers/student/consultations_controller.rb`
- `app/controllers/parent/forums_controller.rb`
- `app/controllers/diagnostic_teacher/feedback_controller.rb`
- `app/views/researcher/items/index.html.erb`

### Phase 3: Service Layer Refactoring (Week 3-4)

**Goal**: Extract business logic from controllers to services

**Tasks**:
1. Create Query Objects for complex queries
2. Create new Service Objects:
   - `GenerateReportService`
   - `NotificationService`
   - `AnalyticsService`
3. Move scoring logic from controller to service
4. Standardize service invocation pattern

### Phase 4: Authorization Upgrade (Week 5)

**Goal**: Move from manual role checks to Pundit policies

**Tasks**:
1. Add Pundit gem
2. Create policy classes for each model
3. Migrate controller checks to policies
4. Add model-level visibility rules

### Phase 5: Background Jobs Implementation (Week 6)

**Goal**: Move long-running tasks to background jobs

**Tasks**:
1. Add ActiveJob + Sidekiq/GoodJob
2. Create background job classes
3. Migrate AI feedback generation to background
4. Implement notification delivery queue

### Phase 6: API Namespace Creation (Week 7)

**Goal**: Separate web UI from API

**Tasks**:
1. Create `/api/v1/` namespace
2. Create API controllers with JSON responses
3. Add API authentication (JWT tokens)
4. Document API endpoints

### Phase 7: Testing & QA (Week 8+)

**Goal**: Achieve 80% test coverage

**Tasks**:
1. Write model tests for all relationships
2. Write controller tests for all actions
3. Write service tests for business logic
4. Write system tests for critical flows
5. Run security scans (Brakeman, Bundler Audit)

---

## Technical Debt Resolution

### Priority P0 (Critical - Week 1-2)

| Item | Issue | Action | Effort |
|---|---|---|---|
| **Seeds File** | References non-existent models | Remove lines 220-226, 356-374 | 0.5 hrs |
| **Missing Models** | Code deleted but still referenced | Restore 7 migrations from backup | 2 hrs |
| **Response-Feedback** | Circular dependency (responses.feedback_id) | Remove foreign key, redesign | 3 hrs |
| **Broken Controllers** | Reference deleted models | Restore or comment out | 2 hrs |

### Priority P1 (High - Week 3-4)

| Item | Issue | Action | Effort |
|---|---|---|---|
| **Parent-Student** | Missing relationship | Implement via GuardianStudent | 3 hrs |
| **Pagination** | Two different approaches | Standardize on Kaminari | 2 hrs |
| **Layouts** | Two layouts in use | Migrate all to unified_portal | 2 hrs |
| **Business Logic** | Scattered across controllers | Extract to services | 8 hrs |

### Priority P2 (Medium - Week 5-6)

| Item | Issue | Action | Effort |
|---|---|---|---|
| **Authorization** | Manual role checks | Implement Pundit policies | 8 hrs |
| **Background Jobs** | No async processing | Implement ActiveJob + Sidekiq | 6 hrs |
| **Query Objects** | Complex queries in controllers | Create Query Object classes | 4 hrs |
| **API Namespace** | No clear API structure | Create /api/v1/ namespace | 6 hrs |

### Priority P3 (Low - Week 7+)

| Item | Issue | Action | Effort |
|---|---|---|---|
| **Form Objects** | Inline validations in controllers | Create form objects | 4 hrs |
| **Tests** | Limited test coverage | Add tests to reach 80% | 16 hrs |
| **Logging** | Limited visibility into operations | Add structured logging | 2 hrs |
| **Monitoring** | No performance monitoring | Implement APM tools | 4 hrs |

### Technical Debt Progress Tracking

```markdown
- [x] Database schema normalized
- [ ] Seeds file fixed
- [ ] Missing models restored
- [ ] Pagination standardized
- [ ] Layouts unified
- [ ] Services extracted
- [ ] Authorization refactored
- [ ] Background jobs implemented
- [ ] API namespace created
- [ ] Test coverage >80%
```

---

## References & Related Documents

- [PRD.md](PRD.md) - Product Requirements Document
- [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) - Detailed schema reference (future)
- [API_SPECIFICATION.md](API_SPECIFICATION.md) - Detailed API endpoints (future)
- [DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md) - Setup and development workflow (future)

---

## Appendix: Glossary

| Term | Definition |
|---|---|
| **RBAC** | Role-Based Access Control |
| **ERD** | Entity-Relationship Diagram |
| **MTTR** | Mean Time To Recover |
| **RPO** | Recovery Point Objective |
| **JWT** | JSON Web Token |
| **API** | Application Programming Interface |
| **RESTful** | Representational State Transfer |

---

## Document History

| Version | Date | Status | Changes |
|---|---|---|---|
| 0.1 | 2026-02-02 | Draft | Initial TRD based on codebase analysis |
| 1.0 | TBD | Final | After stakeholder review and approval |

---

## Document Review & Sign-off

**Document Status**: ✅ Draft - Awaiting Stakeholder Review

**Reviewers Needed**:
- [ ] Technology Lead / CTO
- [ ] Database Administrator
- [ ] DevOps / Infrastructure Team
- [ ] Security Team
- [ ] Product Manager

**Review Comments & Feedback**: [To be collected during review phase]

---

**This TRD provides the technical blueprint for systematically improving ReadingPRO's architecture, resolving technical debt, and establishing scalable patterns for future development.**
