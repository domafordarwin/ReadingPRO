# ReadingPRO - Database Schema Document

**Version**: 1.0.0
**Last Updated**: 2026-02-02
**Status**: Draft - Awaiting Review
**Database**: PostgreSQL 12+

---

## Table of Contents

1. [Schema Overview](#schema-overview)
2. [Tables & Columns](#tables--columns)
3. [Relationships](#relationships)
4. [Constraints & Indexes](#constraints--indexes)
5. [Migration Guide](#migration-guide)
6. [SQL Reference](#sql-reference)

---

## Schema Overview

### Database Statistics

```
Total Tables: 31 (22 existing + 9 new/restored)
Total Columns: 350+
Total Relationships: 60+
Indexes: 80+
Constraints: 50+
```

### Schema Layers

```
USER MANAGEMENT (5 tables)
├── users
├── students
├── teachers
├── parents
├── schools
└── guardian_students (join)

ASSESSMENT CONTENT (9 tables)
├── reading_stimuli
├── items
├── item_choices
├── choice_scores
├── evaluation_indicators
├── sub_indicators
├── rubrics
├── rubric_criteria
└── rubric_levels

TEST ADMINISTRATION (2 tables)
├── diagnostic_forms
└── diagnostic_form_items

ATTEMPT & RESPONSE (3 tables)
├── student_attempts
├── responses
└── response_rubric_scores

FEEDBACK & REPORTING (5 tables)
├── feedbacks
├── feedback_prompts
├── feedback_templates
├── attempt_reports
└── announcements

COMMUNICATION (4 tables)
├── consultation_posts
├── consultation_comments
├── parent_forums
├── parent_forum_comments
├── consultation_requests
├── consultation_request_responses
└── notifications

ANALYTICS (3 tables)
├── student_portfolios
├── school_portfolios
└── audit_logs
```

---

## Tables & Columns

### USER MANAGEMENT LAYER

#### users

```sql
CREATE TABLE users (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  email VARCHAR(255) NOT NULL UNIQUE,
  password_digest VARCHAR(255) NOT NULL,
  role VARCHAR(50) NOT NULL CHECK (role IN ('student', 'teacher', 'parent', 'researcher', 'admin', 'school_admin')),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
```

**Columns**:

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT | PK, auto-increment | Unique user identifier |
| `email` | VARCHAR(255) | NOT NULL, UNIQUE | User login email |
| `password_digest` | VARCHAR(255) | NOT NULL | Bcrypt hashed password |
| `role` | VARCHAR(50) | NOT NULL, CHECK | User role (6 types) |
| `created_at` | TIMESTAMP | NOT NULL, DEFAULT | Record creation time |
| `updated_at` | TIMESTAMP | NOT NULL, DEFAULT | Record update time |

**Relationships**:
- (1) ↔ (M) AuditLog
- (1) → (0/1) Student (has_one)
- (1) → (0/1) Teacher (has_one)
- (1) → (0/1) Parent (has_one)

---

#### students

```sql
CREATE TABLE students (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  user_id BIGINT NOT NULL UNIQUE REFERENCES users,
  school_id BIGINT NOT NULL REFERENCES schools,
  name VARCHAR(255) NOT NULL,
  student_number VARCHAR(50) NOT NULL,
  grade INT CHECK (grade IN (1, 2, 3)),
  class_name VARCHAR(100),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(school_id, student_number)
);

CREATE INDEX idx_students_school_id ON students(school_id);
CREATE INDEX idx_students_user_id ON students(user_id);
```

**Columns**:

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | BIGINT | PK | Student profile ID |
| `user_id` | BIGINT | FK (UNIQUE) | Reference to User |
| `school_id` | BIGINT | FK | Reference to School |
| `name` | VARCHAR(255) | NOT NULL | Student full name |
| `student_number` | VARCHAR(50) | NOT NULL | School-assigned ID |
| `grade` | INT | CHECK (1-3) | Grade level (1=1st year, 2=2nd, 3=3rd) |
| `class_name` | VARCHAR(100) | NULL | Class name/number |
| `created_at` | TIMESTAMP | NOT NULL | Creation time |
| `updated_at` | TIMESTAMP | NOT NULL | Update time |

**Relationships**:
- (M) → (1) School
- (M) ↔ (M) Parent (through GuardianStudent)
- (1) ↔ (M) StudentAttempt
- (1) ↔ (M) ConsultationPost
- (1) ↔ (1) StudentPortfolio

---

#### teachers

```sql
CREATE TABLE teachers (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  user_id BIGINT NOT NULL UNIQUE REFERENCES users,
  school_id BIGINT NOT NULL REFERENCES schools,
  name VARCHAR(255) NOT NULL,
  department VARCHAR(100),
  position VARCHAR(100),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(school_id, user_id)
);

CREATE INDEX idx_teachers_school_id ON teachers(school_id);
CREATE INDEX idx_teachers_user_id ON teachers(user_id);
```

**Columns**: Similar structure to students

**Relationships**:
- (1) ↔ (M) Item (created_by)
- (1) ↔ (M) ReadingStimulus (created_by)
- (1) ↔ (M) DiagnosticForm (created_by)

---

#### parents

```sql
CREATE TABLE parents (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  user_id BIGINT NOT NULL UNIQUE REFERENCES users,
  name VARCHAR(255) NOT NULL,
  phone VARCHAR(20),
  email VARCHAR(255),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_parents_user_id ON parents(user_id);
CREATE INDEX idx_parents_email ON parents(email);
```

**Relationships**:
- (M) ↔ (M) Student (through GuardianStudent)

---

#### schools

```sql
CREATE TABLE schools (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  name VARCHAR(255) NOT NULL UNIQUE,
  region VARCHAR(100),
  district VARCHAR(100),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_schools_name ON schools(name);
CREATE INDEX idx_schools_region ON schools(region);
```

**Relationships**:
- (1) ↔ (M) Student
- (1) ↔ (M) Teacher
- (1) ↔ (1) SchoolPortfolio
- (1) ↔ (M) ParentForum

---

#### guardian_students

```sql
CREATE TABLE guardian_students (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  parent_id BIGINT NOT NULL REFERENCES parents ON DELETE CASCADE,
  student_id BIGINT NOT NULL REFERENCES students ON DELETE CASCADE,
  relationship VARCHAR(50), -- '부', '모', '보호자'
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(parent_id, student_id)
);

CREATE INDEX idx_guardian_students_parent_id ON guardian_students(parent_id);
CREATE INDEX idx_guardian_students_student_id ON guardian_students(student_id);
```

**Purpose**: Many-to-many relationship between parents and students
**Relationships**: Links parents and students

---

### ASSESSMENT CONTENT LAYER

#### evaluation_indicators (NEW)

```sql
CREATE TABLE evaluation_indicators (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  code VARCHAR(100) NOT NULL UNIQUE,
  name TEXT NOT NULL,
  description TEXT,
  level INT DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_evaluation_indicators_code ON evaluation_indicators(code);
```

**Purpose**: Korean national curriculum learning standards

**Columns**:

| Column | Type | Description |
|---|---|---|
| `code` | VARCHAR(100) | Standard code (e.g., 국어.2-1-01) |
| `name` | TEXT | Standard name |
| `level` | INT | Hierarchy level (1=top-level) |

---

#### sub_indicators (NEW)

```sql
CREATE TABLE sub_indicators (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  evaluation_indicator_id BIGINT NOT NULL REFERENCES evaluation_indicators,
  code VARCHAR(100),
  name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(evaluation_indicator_id, code)
);

CREATE INDEX idx_sub_indicators_indicator_id ON sub_indicators(evaluation_indicator_id);
```

**Purpose**: Sub-level standards under evaluation indicators

---

#### reading_stimuli

```sql
CREATE TABLE reading_stimuli (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  title VARCHAR(500) NOT NULL,
  body TEXT NOT NULL,
  source VARCHAR(500),
  word_count INT,
  reading_level VARCHAR(50) CHECK (reading_level IN ('중1', '중2', '중3')),
  created_by_id BIGINT NOT NULL REFERENCES teachers,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_reading_stimuli_reading_level ON reading_stimuli(reading_level);
CREATE INDEX idx_reading_stimuli_created_by_id ON reading_stimuli(created_by_id);
CREATE INDEX idx_reading_stimuli_title_tsvector ON reading_stimuli USING GIN(to_tsvector('korean', title));
```

**Purpose**: Reading passages for comprehension questions

**Full-Text Search**: Uses PostgreSQL tsvector for Korean text search

---

#### items

```sql
CREATE TABLE items (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  code VARCHAR(100) NOT NULL UNIQUE,
  item_type VARCHAR(50) NOT NULL CHECK (item_type IN ('mcq', 'constructed')),
  difficulty VARCHAR(50) NOT NULL CHECK (difficulty IN ('상', '중', '하')),
  status VARCHAR(50) NOT NULL DEFAULT '준비중' CHECK (status IN ('준비중', '활성', '폐기')),
  prompt TEXT NOT NULL,
  explanation TEXT,
  category VARCHAR(100),
  stimulus_id BIGINT REFERENCES reading_stimuli,
  evaluation_indicator_id BIGINT REFERENCES evaluation_indicators,
  sub_indicator_id BIGINT REFERENCES sub_indicators,
  created_by_id BIGINT NOT NULL REFERENCES teachers,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_items_code ON items(code);
CREATE INDEX idx_items_type ON items(item_type);
CREATE INDEX idx_items_difficulty ON items(difficulty);
CREATE INDEX idx_items_status ON items(status);
CREATE INDEX idx_items_stimulus_id ON items(stimulus_id);
CREATE INDEX idx_items_indicator_id ON items(evaluation_indicator_id);
CREATE INDEX idx_items_created_by_id ON items(created_by_id);
CREATE INDEX idx_items_prompt_tsvector ON items USING GIN(to_tsvector('korean', prompt));
```

**Purpose**: Assessment questions

**Columns**:

| Column | Type | Constraints | Description |
|---|---|---|---|
| `code` | VARCHAR(100) | UNIQUE | Item code (e.g., ENG-2026-001) |
| `item_type` | VARCHAR(50) | CHECK | mcq or constructed response |
| `difficulty` | VARCHAR(50) | CHECK | 상(high), 중(medium), 하(low) |
| `status` | VARCHAR(50) | CHECK | 준비중(draft), 활성(active), 폐기(archived) |
| `prompt` | TEXT | NOT NULL | Question text |
| `explanation` | TEXT | NULL | Answer explanation |

---

#### item_choices

```sql
CREATE TABLE item_choices (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  item_id BIGINT NOT NULL REFERENCES items ON DELETE CASCADE,
  choice_no INT NOT NULL,
  content TEXT NOT NULL,
  is_correct BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(item_id, choice_no)
);

CREATE INDEX idx_item_choices_item_id ON item_choices(item_id);
```

**Purpose**: Answer choices for MCQ items

**Columns**:

| Column | Type | Description |
|---|---|---|
| `choice_no` | INT | Choice number (1-5 typical) |
| `content` | TEXT | Choice text |
| `is_correct` | BOOLEAN | Whether this is a correct answer |

---

#### choice_scores

```sql
CREATE TABLE choice_scores (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  item_choice_id BIGINT NOT NULL UNIQUE REFERENCES item_choices,
  score_percent INT NOT NULL CHECK (score_percent >= 0 AND score_percent <= 100),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

**Purpose**: Percentage-based scoring for MCQ choices (not just binary correct/incorrect)

---

#### rubrics

```sql
CREATE TABLE rubrics (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  item_id BIGINT NOT NULL UNIQUE REFERENCES items,
  name VARCHAR(255),
  description TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_rubrics_item_id ON rubrics(item_id);
```

**Purpose**: Scoring rubrics for constructed response items

---

#### rubric_criteria

```sql
CREATE TABLE rubric_criteria (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  rubric_id BIGINT NOT NULL REFERENCES rubrics ON DELETE CASCADE,
  criterion_name VARCHAR(255) NOT NULL,
  description TEXT,
  max_score INT DEFAULT 3,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(rubric_id, criterion_name)
);

CREATE INDEX idx_rubric_criteria_rubric_id ON rubric_criteria(rubric_id);
```

**Purpose**: Individual scoring criteria within a rubric

---

#### rubric_levels

```sql
CREATE TABLE rubric_levels (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  rubric_criterion_id BIGINT NOT NULL REFERENCES rubric_criteria ON DELETE CASCADE,
  level INT NOT NULL CHECK (level >= 0),
  score INT NOT NULL CHECK (score >= 0),
  description TEXT,
  exemplar TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(rubric_criterion_id, level)
);

CREATE INDEX idx_rubric_levels_criterion_id ON rubric_levels(rubric_criterion_id);
```

**Purpose**: Performance levels for each criterion

**Example**:
```
Level 3: "Advanced" - Score: 3
Level 2: "Proficient" - Score: 2
Level 1: "Developing" - Score: 1
Level 0: "Beginning" - Score: 0
```

---

### TEST ADMINISTRATION LAYER

#### diagnostic_forms

```sql
CREATE TABLE diagnostic_forms (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  name VARCHAR(500) NOT NULL,
  description TEXT,
  status VARCHAR(50) DEFAULT 'draft' CHECK (status IN ('draft', '활성', 'archived')),
  item_count INT,
  time_limit_minutes INT,
  difficulty_distribution JSONB, -- {"상": 30, "중": 50, "하": 20}
  created_by_id BIGINT NOT NULL REFERENCES teachers,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_diagnostic_forms_status ON diagnostic_forms(status);
CREATE INDEX idx_diagnostic_forms_created_by_id ON diagnostic_forms(created_by_id);
CREATE INDEX idx_diagnostic_forms_difficulty_distribution ON diagnostic_forms USING GIN(difficulty_distribution);
```

**Purpose**: Configured assessment forms (collections of items)

**JSONB Columns**: `difficulty_distribution` stores distribution percentages

---

#### diagnostic_form_items

```sql
CREATE TABLE diagnostic_form_items (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  diagnostic_form_id BIGINT NOT NULL REFERENCES diagnostic_forms ON DELETE CASCADE,
  item_id BIGINT NOT NULL REFERENCES items,
  position INT NOT NULL,
  points INT,
  section_title VARCHAR(255),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(diagnostic_form_id, item_id),
  UNIQUE(diagnostic_form_id, position)
);

CREATE INDEX idx_diagnostic_form_items_form_id ON diagnostic_form_items(diagnostic_form_id);
CREATE INDEX idx_diagnostic_form_items_item_id ON diagnostic_form_items(item_id);
```

**Purpose**: Join table mapping items to forms with position and points

---

### ATTEMPT & RESPONSE LAYER

#### student_attempts

```sql
CREATE TABLE student_attempts (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  student_id BIGINT NOT NULL REFERENCES students,
  diagnostic_form_id BIGINT NOT NULL REFERENCES diagnostic_forms,
  status VARCHAR(50) DEFAULT 'not_started' CHECK (status IN ('not_started', 'in_progress', 'submitted', 'graded')),
  started_at TIMESTAMP,
  submitted_at TIMESTAMP,
  time_spent_seconds INT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_student_attempts_student_id ON student_attempts(student_id);
CREATE INDEX idx_student_attempts_form_id ON student_attempts(diagnostic_form_id);
CREATE INDEX idx_student_attempts_status ON student_attempts(status);
CREATE INDEX idx_student_attempts_created_at ON student_attempts(created_at);
```

**Purpose**: Student test sessions

**Columns**:

| Column | Type | Description |
|---|---|---|
| `status` | VARCHAR(50) | Session state |
| `time_spent_seconds` | INT | Duration of session |

---

#### responses

```sql
CREATE TABLE responses (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  student_attempt_id BIGINT NOT NULL REFERENCES student_attempts,
  item_id BIGINT NOT NULL REFERENCES items,
  answer_text TEXT,
  selected_choice_id BIGINT REFERENCES item_choices,
  auto_score INT,
  manual_score INT,
  is_correct BOOLEAN,
  status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'scored', 'needs_review')),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(student_attempt_id, item_id)
);

CREATE INDEX idx_responses_attempt_id ON responses(student_attempt_id);
CREATE INDEX idx_responses_item_id ON responses(item_id);
CREATE INDEX idx_responses_status ON responses(status);
```

**Purpose**: Individual student responses to items

**Columns**:

| Column | Type | Description |
|---|---|---|
| `answer_text` | TEXT | Text answer (for constructed response) |
| `selected_choice_id` | BIGINT | Selected MCQ choice |
| `auto_score` | INT | MCQ auto-calculated score |
| `manual_score` | INT | Teacher-assigned score |
| `is_correct` | BOOLEAN | Correctness flag |

---

#### response_rubric_scores

```sql
CREATE TABLE response_rubric_scores (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  response_id BIGINT NOT NULL REFERENCES responses ON DELETE CASCADE,
  rubric_criterion_id BIGINT NOT NULL REFERENCES rubric_criteria,
  level_score INT NOT NULL CHECK (level_score >= 0 AND level_score <= 4),
  feedback TEXT,
  created_by_id BIGINT NOT NULL REFERENCES teachers,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_response_rubric_scores_response_id ON response_rubric_scores(response_id);
CREATE INDEX idx_response_rubric_scores_criterion_id ON response_rubric_scores(rubric_criterion_id);
```

**Purpose**: Rubric-based scores for constructed responses

---

### FEEDBACK & REPORTING LAYER

#### feedbacks

```sql
CREATE TABLE feedbacks (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  response_id BIGINT NOT NULL REFERENCES responses ON DELETE CASCADE,
  content TEXT NOT NULL,
  feedback_type VARCHAR(50) CHECK (feedback_type IN ('ai_generated', 'teacher_custom', 'template_based')),
  is_auto_generated BOOLEAN DEFAULT FALSE,
  score_override INT,
  created_by_id BIGINT REFERENCES teachers,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_feedbacks_response_id ON feedbacks(response_id);
CREATE INDEX idx_feedbacks_created_by_id ON feedbacks(created_by_id);
CREATE INDEX idx_feedbacks_created_at ON feedbacks(created_at);
```

**Purpose**: Teacher or AI-generated feedback on responses

---

#### feedback_prompts (NEW)

```sql
CREATE TABLE feedback_prompts (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  name VARCHAR(500) NOT NULL,
  category VARCHAR(100),
  item_type VARCHAR(50) CHECK (item_type IN ('mcq', 'constructed')),
  template_text TEXT NOT NULL,
  variables JSONB,
  version INT DEFAULT 1,
  is_active BOOLEAN DEFAULT TRUE,
  created_by_id BIGINT REFERENCES teachers,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_feedback_prompts_name ON feedback_prompts(name);
CREATE INDEX idx_feedback_prompts_category ON feedback_prompts(category);
CREATE INDEX idx_feedback_prompts_is_active ON feedback_prompts(is_active);
```

**Purpose**: Prompt templates for AI feedback generation

**JSONB**: `variables` stores template variables (e.g., {"student_name": true, "score": true})

---

#### attempt_reports

```sql
CREATE TABLE attempt_reports (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  student_attempt_id BIGINT NOT NULL UNIQUE REFERENCES student_attempts,
  total_score DECIMAL(8, 2),
  max_score DECIMAL(8, 2),
  score_percentage DECIMAL(5, 2),
  performance_level VARCHAR(50),
  strengths JSONB,
  weaknesses JSONB,
  recommendations JSONB,
  generated_at TIMESTAMP,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_attempt_reports_attempt_id ON attempt_reports(student_attempt_id);
CREATE INDEX idx_attempt_reports_generated_at ON attempt_reports(generated_at);
```

**Purpose**: Generated assessment reports

**JSONB Columns**:
- `strengths`: Array of strength areas
- `weaknesses`: Array of weakness areas
- `recommendations`: Array of recommendations

---

#### announcements

```sql
CREATE TABLE announcements (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  title VARCHAR(500) NOT NULL,
  content TEXT NOT NULL,
  priority VARCHAR(50) DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high')),
  published_at TIMESTAMP,
  published_by_id BIGINT REFERENCES teachers,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_announcements_published_at ON announcements(published_at);
CREATE INDEX idx_announcements_priority ON announcements(priority);
```

---

### COMMUNICATION LAYER (NEW)

#### consultation_posts

```sql
CREATE TABLE consultation_posts (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  student_id BIGINT NOT NULL REFERENCES students,
  title VARCHAR(500) NOT NULL,
  body TEXT NOT NULL,
  category VARCHAR(100),
  status VARCHAR(50) DEFAULT 'open' CHECK (status IN ('open', 'answered', 'closed')),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_consultation_posts_student_id ON consultation_posts(student_id);
CREATE INDEX idx_consultation_posts_status ON consultation_posts(status);
```

---

#### consultation_comments

```sql
CREATE TABLE consultation_comments (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  consultation_post_id BIGINT NOT NULL REFERENCES consultation_posts ON DELETE CASCADE,
  user_id BIGINT NOT NULL REFERENCES users,
  body TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_consultation_comments_post_id ON consultation_comments(consultation_post_id);
CREATE INDEX idx_consultation_comments_user_id ON consultation_comments(user_id);
```

---

#### parent_forums

```sql
CREATE TABLE parent_forums (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  school_id BIGINT NOT NULL REFERENCES schools,
  user_id BIGINT NOT NULL REFERENCES users,
  title VARCHAR(500) NOT NULL,
  body TEXT NOT NULL,
  category VARCHAR(100),
  status VARCHAR(50) DEFAULT 'open' CHECK (status IN ('open', 'locked', 'archived')),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_parent_forums_school_id ON parent_forums(school_id);
CREATE INDEX idx_parent_forums_user_id ON parent_forums(user_id);
CREATE INDEX idx_parent_forums_status ON parent_forums(status);
```

---

#### parent_forum_comments

```sql
CREATE TABLE parent_forum_comments (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  parent_forum_id BIGINT NOT NULL REFERENCES parent_forums ON DELETE CASCADE,
  user_id BIGINT NOT NULL REFERENCES users,
  body TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_parent_forum_comments_forum_id ON parent_forum_comments(parent_forum_id);
CREATE INDEX idx_parent_forum_comments_user_id ON parent_forum_comments(user_id);
```

---

#### consultation_requests

```sql
CREATE TABLE consultation_requests (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  student_id BIGINT NOT NULL REFERENCES students,
  user_id BIGINT NOT NULL REFERENCES users,
  consultation_type VARCHAR(100),
  requested_date TIMESTAMP NOT NULL,
  notes TEXT NOT NULL,
  status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'completed')),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_consultation_requests_student_id ON consultation_requests(student_id);
CREATE INDEX idx_consultation_requests_user_id ON consultation_requests(user_id);
CREATE INDEX idx_consultation_requests_status ON consultation_requests(status);
```

---

#### consultation_request_responses

```sql
CREATE TABLE consultation_request_responses (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  consultation_request_id BIGINT NOT NULL REFERENCES consultation_requests,
  teacher_id BIGINT NOT NULL REFERENCES teachers,
  response_status VARCHAR(50) CHECK (response_status IN ('approved', 'rejected', 'reschedule_requested')),
  approved_date TIMESTAMP,
  response_notes TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_consult_request_responses_request_id ON consultation_request_responses(consultation_request_id);
```

---

#### notifications (NEW)

```sql
CREATE TABLE notifications (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  user_id BIGINT NOT NULL REFERENCES users ON DELETE CASCADE,
  title VARCHAR(500) NOT NULL,
  message TEXT NOT NULL,
  notification_type VARCHAR(100),
  resource_type VARCHAR(100),
  resource_id BIGINT,
  is_read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMP,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);
```

---

### ANALYTICS LAYER

#### student_portfolios

```sql
CREATE TABLE student_portfolios (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  student_id BIGINT NOT NULL UNIQUE REFERENCES students,
  total_attempts INT DEFAULT 0,
  total_score DECIMAL(10, 2),
  average_score DECIMAL(10, 2),
  improvement_trend JSONB,
  last_updated_at TIMESTAMP,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_student_portfolios_student_id ON student_portfolios(student_id);
```

**JSONB**: `improvement_trend` stores historical scores

---

#### school_portfolios

```sql
CREATE TABLE school_portfolios (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  school_id BIGINT NOT NULL UNIQUE REFERENCES schools,
  total_students INT,
  total_attempts INT,
  average_score DECIMAL(10, 2),
  performance_by_category JSONB,
  difficulty_distribution JSONB,
  last_updated_at TIMESTAMP,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_school_portfolios_school_id ON school_portfolios(school_id);
```

---

#### audit_logs

```sql
CREATE TABLE audit_logs (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  user_id BIGINT REFERENCES users,
  action VARCHAR(255) NOT NULL,
  resource_type VARCHAR(100),
  resource_id BIGINT,
  changes JSONB,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);
CREATE INDEX idx_audit_logs_resource ON audit_logs(resource_type, resource_id);
```

---

## Relationships

### Entity Relationship Diagram (Text Representation)

```
User (1) ────────────── (M) AuditLog
  ├── (1)──────(1) Student
  ├── (1)──────(1) Teacher
  └── (1)──────(1) Parent

Student (M) ────────────── (1) School
  ├── (M)──────(1) GuardianStudent──(M) Parent
  ├── (1)──────(M) StudentAttempt
  ├── (1)──────(M) ConsultationPost
  ├── (1)──────(M) ConsultationRequest
  └── (1)──────(1) StudentPortfolio

Teacher (M) ────────────── (1) School
  ├── (1)──────(M) Item (created_by)
  ├── (1)──────(M) ReadingStimulus
  ├── (1)──────(M) DiagnosticForm
  ├── (1)──────(M) Feedback
  └── (1)──────(M) ResponseRubricScore

ReadingStimulus (1) ────────────── (M) Item
Item (1) ────────────── (M) ItemChoice
  ├── (1)──────(M) DiagnosticFormItem──(M) DiagnosticForm
  ├── (1)──────(M) Response
  ├── (1)──────(1) Rubric
  ├── (M)──────(1) EvaluationIndicator
  └── (M)──────(1) SubIndicator

ItemChoice (1) ────────────── (1) ChoiceScore
ItemChoice (1) ────────────── (M) Response (selected_choice)

Rubric (1) ────────────── (M) RubricCriterion
RubricCriterion (1) ────────────── (M) RubricLevel

DiagnosticForm (1) ────────────── (M) StudentAttempt
StudentAttempt (1) ────────────── (M) Response
  └── (1)──────(1) AttemptReport

Response (1) ────────────── (M) ResponseRubricScore
Response (1) ────────────── (M) Feedback
Response (1)──────(0/1) Feedback (REMOVED - see migrations)

School (1) ────────────── (M) Student
  ├── (M)────────── Teacher
  ├── (1)──────(1) SchoolPortfolio
  └── (1)──────(M) ParentForum

ConsultationPost (1) ────────────── (M) ConsultationComment

ParentForum (1) ────────────── (M) ParentForumComment

ConsultationRequest (1) ────────────── (M) ConsultationRequestResponse
```

---

## Constraints & Indexes

### Primary Key Constraints

All tables have `id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY`

**Rationale**: Auto-incrementing 64-bit integers support large scale (~9.2 quintillion records)

### Foreign Key Constraints

All FKs use `ON DELETE CASCADE` for referential integrity

**Exception**: `guardian_students` uses `ON DELETE CASCADE` to remove relationships when parents/students deleted

### Unique Constraints

```sql
-- User table
UNIQUE(email)

-- Student/Teacher
UNIQUE(user_id)
UNIQUE(school_id, student_number)
UNIQUE(school_id, user_id)

-- Content
UNIQUE(code) -- Item code unique
UNIQUE(item_id) -- One rubric per item
UNIQUE(rubric_id, criterion_name)
UNIQUE(rubric_criterion_id, level)

-- Relationships
UNIQUE(diagnostic_form_id, item_id)
UNIQUE(diagnostic_form_id, position)
UNIQUE(parent_id, student_id)
UNIQUE(student_attempt_id, item_id)

-- Analytics
UNIQUE(student_id)
UNIQUE(school_id)
```

### Check Constraints

```sql
-- Role validation
CHECK(role IN ('student', 'teacher', 'parent', 'researcher', 'admin', 'school_admin'))

-- Grade validation
CHECK(grade IN (1, 2, 3))

-- Enum validations
CHECK(item_type IN ('mcq', 'constructed'))
CHECK(difficulty IN ('상', '중', '하'))
CHECK(status IN ('준비중', '활성', '폐기'))
CHECK(reading_level IN ('중1', '중2', '중3'))

-- Numeric validations
CHECK(score_percent >= 0 AND score_percent <= 100)
CHECK(level >= 0)
CHECK(level_score >= 0 AND level_score <= 4)
```

### Indexes

**Strategy**: Index frequently queried columns for optimal performance

**Index Types**:
1. **B-tree** (default): Primary keys, foreign keys, exact matches
2. **GIN** (Generalized Inverted Index): JSONB columns, full-text search
3. **Hash**: Not used (limited utility for range queries)

**Top 20 Indexes**:

| Table | Column(s) | Type | Purpose |
|---|---|---|---|
| users | email | B-tree | Fast login lookup |
| students | school_id, user_id | B-tree | Find students by school |
| items | code | B-tree | Quick item code lookup |
| items | type, difficulty, status | B-tree | Filter queries |
| items | prompt (tsvector) | GIN | Full-text search |
| reading_stimuli | reading_level | B-tree | Filter by level |
| responses | attempt_id, item_id | B-tree | Find responses |
| student_attempts | student_id | B-tree | Student history |
| feedback_prompts | is_active | B-tree | Get active templates |
| audit_logs | created_at | B-tree | Time-range queries |

---

## Migration Guide

### From Current (22 tables) to Target (31 tables)

**New Tables to Create** (9):

1. `evaluation_indicators` - Learning standards
2. `sub_indicators` - Sub-level standards
3. `feedback_prompts` - AI prompt templates
4. `consultation_posts` - Student consultation board
5. `consultation_comments` - Comments on consultations
6. `parent_forums` - Parent discussion forums
7. `parent_forum_comments` - Forum comments
8. `consultation_requests` - Parent consultation requests
9. `consultation_request_responses` - Teacher responses
10. `notifications` - System notifications

**Tables to Modify**:
- Add `guardian_students` join table if not exists
- Fix `responses` table (remove circular FK if exists)
- Add missing indexes and constraints

**Migration Scripts**: See MIGRATION_RUNBOOK.md

---

## SQL Reference

### Create All Tables (Complete Script)

```bash
# Run individual migration files
bin/rails db:migrate

# Or use Rails console to inspect schema
rails console
> ApplicationRecord.connection.tables
> ApplicationRecord.connection.columns('items')
```

### View Current Schema

```sql
-- List all tables
SELECT tablename FROM pg_catalog.pg_tables
WHERE schemaname = 'public';

-- View table structure
\d items

-- View all indexes
SELECT * FROM pg_indexes
WHERE tablename = 'items';

-- View constraints
SELECT constraint_name, constraint_type
FROM information_schema.table_constraints
WHERE table_name = 'items';
```

### Common Queries

```sql
-- Recent student attempts
SELECT sa.*, s.name, df.name as form_name
FROM student_attempts sa
JOIN students s ON sa.student_id = s.id
JOIN diagnostic_forms df ON sa.diagnostic_form_id = df.id
ORDER BY sa.created_at DESC
LIMIT 10;

-- Items by evaluation indicator
SELECT i.code, i.prompt, i.difficulty, ei.name
FROM items i
JOIN evaluation_indicators ei ON i.evaluation_indicator_id = ei.id
WHERE ei.id = ?;

-- Teacher feedback generation history
SELECT f.id, f.created_at, f.feedback_type, COUNT(*) as count
FROM feedbacks f
WHERE f.created_by_id = ? AND f.created_at > NOW() - INTERVAL '30 days'
GROUP BY f.feedback_type, DATE(f.created_at)
ORDER BY f.created_at DESC;

-- School portfolio statistics
SELECT sp.*, s.name as school_name
FROM school_portfolios sp
JOIN schools s ON sp.school_id = s.id
WHERE sp.average_score > 80
ORDER BY sp.average_score DESC;
```

---

## Performance Optimization

### Query Optimization Tips

1. **Use eager loading**: `Item.includes(:stimulus, :evaluation_indicator).find(id)`
2. **Index foreign keys**: All FKs indexed for join performance
3. **Partition large tables**: `student_attempts` and `responses` benefit from date-based partitioning
4. **Analyze slow queries**: Use `EXPLAIN ANALYZE` for large queries
5. **Cache frequently accessed data**: Use Redis for portfolios, statistics

### Backup & Maintenance

```sql
-- Regular VACUUM and ANALYZE
VACUUM ANALYZE items;

-- Monitor table size
SELECT schemaname, tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Reindex fragmented indexes
REINDEX TABLE items;
```

---

## Document History

| Version | Date | Status | Changes |
|---|---|---|---|
| 0.1 | 2026-02-02 | Draft | Initial schema documentation |
| 1.0 | TBD | Final | After database normalization |

**This schema document is the source of truth for all database design decisions. All queries and migrations should reference this document.**
