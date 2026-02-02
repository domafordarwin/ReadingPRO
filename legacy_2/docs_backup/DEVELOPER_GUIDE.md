# ReadingPRO - Developer Guide

**Version**: 1.0.0
**Last Updated**: 2026-02-02
**Status**: Draft - Awaiting Review
**Audience**: Development Team

---

## Table of Contents

1. [Getting Started](#getting-started)
2. [Development Environment](#development-environment)
3. [Project Structure](#project-structure)
4. [Code Standards](#code-standards)
5. [Development Workflow](#development-workflow)
6. [Testing](#testing)
7. [Debugging](#debugging)
8. [Common Tasks](#common-tasks)

---

## Getting Started

### Prerequisites

- **Ruby**: 3.4.x (check `.ruby-version`)
- **Rails**: 8.1+ (check `Gemfile`)
- **PostgreSQL**: 12+ (local development)
- **Node.js**: 18+ (for asset pipeline)
- **Git**: Latest version

### Initial Setup

```bash
# 1. Clone repository
git clone https://github.com/your-org/readingpro.git
cd readingpro

# 2. Install dependencies
bundle install

# 3. Install Node packages
yarn install

# 4. Setup database
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed

# 5. Start Rails server
bin/rails server

# 6. Open browser
open http://localhost:3000
```

### Verify Setup

```bash
# Run tests
bin/rails test

# Check code quality
bin/rubocop
bin/brakeman --no-pager

# Check dependencies
bin/bundler-audit
```

---

## Development Environment

### macOS / Linux

```bash
# Ruby version manager (recommended: rbenv or rvm)
rbenv install 3.4.0
rbenv local 3.4.0

# PostgreSQL (macOS)
brew install postgresql@16
brew services start postgresql@16

# Create dev database
createdb readingpro_development
createuser readingpro_user --createdb

# Edit config/database.yml
username: readingpro_user
password: password
```

### Windows

```bash
# Use WSL2 (Windows Subsystem for Linux)
wsl --install

# Inside WSL:
sudo apt-get update
sudo apt-get install ruby-full postgresql

# Platform-specific gems
bundle lock --add-platform x86_64-linux ruby
```

### Docker (Alternative)

```yaml
# docker-compose.yml
version: '3.8'
services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_USER: readingpro_user
      POSTGRES_PASSWORD: password
      POSTGRES_DB: readingpro_development
    ports:
      - "5432:5432"

  app:
    build: .
    command: bin/rails server -b 0.0.0.0
    ports:
      - "3000:3000"
    depends_on:
      - postgres
    volumes:
      - .:/app
```

### Environment Variables

Create `.env` file in project root:

```bash
# .env (development)
DATABASE_URL=postgresql://readingpro_user:password@localhost/readingpro_development
RAILS_ENV=development
RAILS_MASTER_KEY=your-master-key-here
OPENAI_API_KEY=sk-...
REDIS_URL=redis://localhost:6379/1
```

**Important**: Never commit `.env` file to git

---

## Project Structure

```
readingpro/
├── app/
│   ├── models/           # Domain models (22 tables)
│   │   ├── user.rb
│   │   ├── item.rb
│   │   ├── student.rb
│   │   └── ...
│   ├── controllers/      # 6 portal namespaces
│   │   ├── admin/
│   │   ├── student/
│   │   ├── parent/
│   │   ├── diagnostic_teacher/
│   │   ├── school_admin/
│   │   └── researcher/
│   ├── services/         # Business logic
│   │   ├── score_response_service.rb
│   │   ├── feedback_ai_service.rb
│   │   └── ...
│   ├── views/            # ERB templates (SSR)
│   │   ├── layouts/
│   │   ├── shared/
│   │   ├── admin/
│   │   └── ...
│   └── helpers/
│
├── config/
│   ├── routes.rb         # Namespace routing
│   ├── database.yml      # Database config
│   ├── initializers/     # Custom configuration
│   └── environments/
│
├── db/
│   ├── migrate/          # Database migrations
│   ├── seeds.rb          # Initial data
│   └── schema.rb         # Current schema
│
├── test/                 # Test files
│   ├── models/
│   ├── controllers/
│   ├── services/
│   └── system/
│
├── docs/                 # Documentation
│   ├── PRD.md
│   ├── TRD.md
│   ├── API_SPECIFICATION.md
│   ├── DATABASE_SCHEMA.md
│   ├── DEVELOPER_GUIDE.md (this file)
│   ├── DEPLOYMENT_GUIDE.md
│   └── MIGRATION_RUNBOOK.md
│
├── lib/                  # Utility modules
│   └── tasks/            # Rake tasks
│
├── public/               # Static files
├── Gemfile               # Ruby dependencies
├── Rakefile              # Rake tasks
├── config.ru             # Rack config
└── README.md
```

---

## Code Standards

### Ruby Naming Conventions

```ruby
# Classes: PascalCase
class UserController
class StudentPortfolio

# Methods & Variables: snake_case
def create_item
def student_name

# Constants: UPPER_SNAKE_CASE
MAX_ATTEMPTS = 5
API_TIMEOUT = 30

# Boolean methods: end with ?
def active?
def can_edit?

# Methods that modify: end with !
def publish!
def archive!
```

### File Organization

```ruby
# app/models/item.rb
class Item < ApplicationRecord
  # 1. Constants
  DIFFICULTY_LEVELS = %w[상 중 하].freeze

  # 2. Associations
  has_many :item_choices, dependent: :destroy
  belongs_to :stimulus, optional: true

  # 3. Enums
  enum :item_type, { mcq: 'mcq', constructed: 'constructed' }
  enum :difficulty, { '상': 'high', '중': 'medium', '하': 'low' }

  # 4. Validations
  validates :code, presence: true, uniqueness: true
  validates :prompt, presence: true, length: { minimum: 10 }

  # 5. Scopes
  scope :active, -> { where(status: 'active') }
  scope :by_type, ->(type) { where(item_type: type) }

  # 6. Callbacks
  before_save :normalize_whitespace

  # 7. Class methods
  class << self
    def recent(limit = 10)
      order(created_at: :desc).limit(limit)
    end
  end

  # 8. Instance methods
  def difficulty_label
    I18n.t("difficulties.#{difficulty}")
  end
end
```

### Controller Standards

```ruby
# app/controllers/researcher/items_controller.rb
class Researcher::ItemsController < ApplicationController
  before_action :require_login
  before_action -> { require_role("researcher") }
  before_action :set_item, only: [:show, :edit, :update, :destroy]

  # Standard REST actions (in order)
  def index; end
  def show; end
  def new; end
  def create; end
  def edit; end
  def update; end
  def destroy; end

  private

  def set_item
    @item = Item.find(params[:id])
  end

  def item_params
    params.require(:item).permit(:code, :prompt, :difficulty, ...)
  end
end
```

### RuboCop Configuration

```yaml
# .rubocop.yml
AllCops:
  TargetRubyVersion: 3.4
  Exclude:
    - 'db/**/*'
    - 'config/**/*'
    - 'bin/**/*'

Metrics/LineLength:
  Max: 120

Metrics/MethodLength:
  Max: 30

Metrics/ClassLength:
  Max: 150

Metrics/BlockLength:
  Exclude:
    - 'config/**/*'
    - 'db/migrate/*'
```

### Run RuboCop

```bash
# Check for style issues
bin/rubocop

# Auto-fix issues
bin/rubocop -a

# Check specific file
bin/rubocop app/models/item.rb
```

---

## Development Workflow

### Git Workflow (Gitflow)

```bash
# 1. Start new feature
git checkout -b feature/add-feedback-templates

# 2. Make commits (atomic, descriptive)
git commit -m "Add feedback prompt template model"
git commit -m "Implement feedback template creation form"

# 3. Push to remote
git push origin feature/add-feedback-templates

# 4. Create Pull Request (GitHub)
# Description includes:
# - What: Feature/bugfix/refactor description
# - Why: Motivation for the change
# - How: Technical approach
# - Testing: Manual testing steps

# 5. Code review & CI checks
# - GitHub Actions runs tests
# - RuboCop, Brakeman checks pass
# - At least 1 approval

# 6. Merge to main
git merge --no-ff feature/add-feedback-templates
git push origin main

# 7. Deploy (see DEPLOYMENT_GUIDE.md)
```

### Commit Message Format

```
<type>: <subject> (max 70 chars)

<body (optional)>

<footer (optional)>
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code reorganization (no behavior change)
- `perf`: Performance improvement
- `test`: Test additions/modifications
- `docs`: Documentation changes
- `chore`: Maintenance (dependencies, configs)

**Examples**:

```
feat: Add consultation request approval workflow

- Implement ConsultationRequestResponse model
- Add teacher approval form to dashboard
- Send email notification to parents

Closes #123

fix: Correct MCQ scoring calculation

Previous: Selected choice score / total choices
Fixed: Use choice_scores.score_percent from database

Fixes #456
```

### Feature Development Checklist

- [ ] Create feature branch from `main`
- [ ] Implement feature with tests
- [ ] Run `bin/rails test` locally
- [ ] Run `bin/rubocop -a` for style fixes
- [ ] Run `bin/brakeman --no-pager` for security
- [ ] Update documentation (README, docs/, inline comments)
- [ ] Commit with descriptive message
- [ ] Push to remote
- [ ] Create Pull Request with detailed description
- [ ] Address code review comments
- [ ] Merge after approval
- [ ] Delete feature branch

---

## Testing

### Test Structure

```
test/
├── models/
│   ├── user_test.rb
│   ├── item_test.rb
│   └── ...
├── controllers/
│   ├── researcher/
│   │   └── items_controller_test.rb
│   └── ...
├── services/
│   ├── score_response_service_test.rb
│   └── ...
├── system/
│   ├── student_takes_assessment_test.rb
│   └── ...
└── fixtures/
    ├── users.yml
    ├── items.yml
    └── ...
```

### Running Tests

```bash
# Run all tests
bin/rails test

# Run specific test file
bin/rails test test/models/item_test.rb

# Run specific test
bin/rails test test/models/item_test.rb:ItemTest::test_requires_code

# Run tests in parallel
bin/rails test --jobs 4

# Run system tests
bin/rails test:system

# Generate coverage report
bundle exec simplecov

# Continuous testing (watch file changes)
bundle exec guard
```

### Writing Tests

```ruby
# test/models/item_test.rb
class ItemTest < ActiveSupport::TestCase
  setup do
    @item = items(:math_001)
  end

  test "requires code and prompt" do
    assert @item.valid?
    @item.code = nil
    refute @item.valid?
  end

  test "code must be unique" do
    duplicate = Item.new(code: @item.code, prompt: "Test")
    refute duplicate.save
  end

  test "associated choices destroy with item" do
    choice_count = ItemChoice.count
    @item.destroy
    assert_equal choice_count - @item.item_choices.count, ItemChoice.count
  end
end

# test/controllers/researcher/items_controller_test.rb
class Researcher::ItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:researcher)
    login_as(@user)
  end

  test "get index lists items" do
    get researcher_items_path
    assert_response :success
    assert_includes response.body, items(:math_001).code
  end

  test "requires researcher role" do
    @user.update(role: 'student')
    get researcher_items_path
    assert_response :forbidden
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
    assert result[:is_correct]
  end
end
```

### Test Fixtures

```yaml
# test/fixtures/items.yml
math_001:
  code: MATH-2026-001
  item_type: mcq
  difficulty: high
  status: active
  prompt: What is 2 + 2?
  explanation: The answer is 4
  created_by: teacher_1
```

---

## Debugging

### Rails Console

```bash
# Interactive Rails console
bin/rails console

# Load data
> item = Item.find(123)
> item.inspect

# Test code
> ScoreResponseService.call(response_id)

# Database queries
> Item.where(status: 'active').explain
```

### Logging

```ruby
# In code
Rails.logger.info("Starting assessment: #{attempt.id}")
Rails.logger.debug("Response data: #{response.inspect}")
Rails.logger.warn("Low score detected: #{score}")
Rails.logger.error("Failed to generate feedback", error: $!)

# View logs
tail -f log/development.log
```

### Debugger

```ruby
# app/services/feedback_ai_service.rb
class FeedbackAiService
  def generate_feedback(response)
    debugger  # Execution pauses here
    # Inspect variables in REPL
    # Continue with 'c' command
  end
end
```

### Inspect SQL Queries

```bash
# In console
> Item.where(difficulty: 'high').explain
QUERY PLAN
  Seq Scan on items i  (cost=0.00..10.50 rows=50)
    Filter: difficulty = 'high'

# Better way
> Item.where(difficulty: 'high').explain(:analyze)
# Shows actual execution time
```

### Common Issues & Solutions

| Issue | Cause | Solution |
|---|---|---|
| `PG::ConnectionBad` | PostgreSQL not running | `brew services start postgresql@16` |
| `Bundler::GemNotFound` | Missing gem | `bundle install` |
| `ArgumentError: invalid byte sequence in UTF-8` | Encoding issue | Check file encoding (should be UTF-8) |
| `ActiveRecord::RecordNotFound` | Record doesn't exist | Add error handling: `rescue ActiveRecord::RecordNotFound` |
| `NoMethodError` | Method doesn't exist | Check model/controller for typos |

---

## Common Tasks

### Create Migration

```bash
# Generate migration file
bin/rails generate migration CreateItems

# Edit db/migrate/xxx_create_items.rb
class CreateItems < ActiveRecord::Migration[8.0]
  def change
    create_table :items do |t|
      t.string :code, null: false
      t.string :item_type, null: false
      t.references :stimulus, foreign_key: true
      t.timestamps
    end

    add_index :items, :code, unique: true
  end
end

# Run migration
bin/rails db:migrate

# Rollback if needed
bin/rails db:rollback
```

### Add New Model

```bash
# Generate model
bin/rails generate model Item code:string item_type:string difficulty:string stimulus:references

# Update associations in app/models/item.rb
# Write tests in test/models/item_test.rb
# Create/update database migration
# Run: bin/rails db:migrate
```

### Add New Controller Action

```bash
# In app/controllers/researcher/items_controller.rb

def bulk_import
  @form = BulkImportForm.new
end

def process_bulk_import
  @form = BulkImportForm.new(bulk_import_params)
  if @form.save
    redirect_to researcher_items_path, notice: 'Items imported'
  else
    render :bulk_import, status: :unprocessable_entity
  end
end

private

def bulk_import_params
  params.require(:bulk_import).permit(:file)
end
```

### Debug API Endpoint

```bash
# Test API with curl
curl -X GET http://localhost:3000/api/v1/items \
  -H "Authorization: Bearer token" \
  -H "Accept: application/json"

# Test with HTTPie
http GET localhost:3000/api/v1/items \
  'Authorization: Bearer token'

# Inspect response
bin/rails console
> require 'net/http'
> resp = Net::HTTP.get_response(URI('http://localhost:3000/api/v1/items?page=1'))
> JSON.parse(resp.body)
```

---

## Performance Tips

### N+1 Query Prevention

```ruby
# Bad: causes multiple queries
items = Item.all
items.each { |item| item.stimulus.title }

# Good: eager load associations
items = Item.includes(:stimulus)
items.each { |item| item.stimulus.title }

# Even better: select specific columns
items = Item.includes(:stimulus).select('items.id', 'items.code')
```

### Caching

```ruby
# Fragment caching (in view)
<% cache @item do %>
  <%= render @item %>
<% end %>

# Page caching (in controller)
caches_page :show

# Query caching
Rails.cache.fetch("item_#{id}") { Item.find(id) }
```

### Database Query Optimization

```ruby
# Add index for frequently filtered columns
add_index :items, :difficulty
add_index :items, :status
add_index :responses, [:student_attempt_id, :item_id]

# Use select to fetch only needed columns
Item.select(:id, :code, :prompt).where(status: 'active')
```

---

## Development Tools

### Recommended VS Code Extensions

```
- Ruby (Shopify)
- Rails (Braylen)
- PostgreSQL (Chris Kolkman)
- Thunder Client (REST API testing)
- GitLens (Git history)
```

### Useful Gems (Development Only)

```ruby
# Gemfile
group :development do
  gem 'pry-rails'        # Better console
  gem 'web-console'      # Console in browser
  gem 'guard-rails'      # Auto-reload on changes
  gem 'bullet'           # Detect N+1 queries
  gem 'rack-mini-profiler' # Profile requests
end

group :development, :test do
  gem 'factory_bot_rails'
  gem 'faker'            # Generate fake data
end
```

### Git Aliases

```bash
# .gitconfig
[alias]
  st = status
  co = checkout
  br = branch
  ci = commit
  unstage = reset HEAD --
  last = log -1 HEAD
  visual = log --graph --oneline --all
```

---

## Resources

- [Rails Guides](https://guides.rubyonrails.org)
- [Ruby Documentation](https://docs.ruby-lang.org/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Project TRD](TRD.md) - Technical Requirements
- [Project API Spec](API_SPECIFICATION.md) - API Reference

---

## Document History

| Version | Date | Changes |
|---|---|---|
| 0.1 | 2026-02-02 | Initial developer guide |
| 1.0 | TBD | Final version after team review |

---

**Welcome to the ReadingPRO development team! This guide helps ensure consistency and quality across the codebase. Please refer to other documentation files for system architecture, database design, and deployment procedures.**
