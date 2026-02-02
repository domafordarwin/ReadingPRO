# ReadingPRO v2.0 - P0 Implementation Design

**Document**: P0 Implementation Design Plan
**Version**: 1.0.0
**Created**: 2026-02-03
**Status**: Ready for Implementation
**Last Updated**: 2026-02-03

> This document contains the comprehensive design for implementing the 4 P0 (Priority 0) items that are critical blockers for ReadingPRO v2.0 development.

---

## Executive Summary

This document provides the detailed design for the **4 P0 items** identified for immediate implementation:

1. **EvaluationIndicator** - Learning standards table & model
2. **SubIndicator** - Sub-level standards table & model
3. **Item Model Modifications** - Adding indicator relationships
4. **API /api/v1 Namespace** - RESTful API foundation

**Total Implementation**: ~1,000 lines of code across 16 files
**Estimated Duration**: 19-27 hours (1-2 developers, 2-3 weeks)
**Complexity**: Medium (database + API + testing)

---

## Part 1: EvaluationIndicator Design

### Database Schema

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
CREATE INDEX idx_evaluation_indicators_level ON evaluation_indicators(level);
```

### Model Implementation

```ruby
# app/models/evaluation_indicator.rb
class EvaluationIndicator < ApplicationRecord
  has_many :sub_indicators, dependent: :destroy
  has_many :items, dependent: :nullify

  validates :code, presence: true, uniqueness: true, length: { minimum: 3, maximum: 100 }
  validates :name, presence: true, length: { minimum: 5, maximum: 500 }
  validates :level, presence: true, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 5 }
  validates :description, length: { maximum: 2000 }, allow_nil: true

  scope :by_level, ->(level) { where(level: level) }
  scope :by_code_pattern, ->(pattern) { where('code ILIKE ?', "%#{pattern}%") }
  scope :with_sub_indicators, -> { includes(:sub_indicators) }
  scope :top_level, -> { where(level: 1) }
  scope :active, -> { where.not(items_count: 0) }

  before_save :normalize_code

  class << self
    def search(query)
      where('code ILIKE ? OR name ILIKE ? OR description ILIKE ?',
            "%#{query}%", "%#{query}%", "%#{query}%")
    end

    def import_from_curriculum(curriculum_data)
      transaction do
        curriculum_data.each do |data|
          find_or_create_by!(code: data[:code]) do |indicator|
            indicator.name = data[:name]
            indicator.description = data[:description]
            indicator.level = data[:level] || 1
          end
        end
      end
    end
  end

  def to_s
    "#{code}: #{name}"
  end

  def full_description
    "#{code} - #{name}" + (description.present? ? "\n#{description}" : "")
  end

  def item_count
    items.count
  end

  private

  def normalize_code
    self.code = code.strip.upcase if code.present?
  end
end
```

### Migration

```ruby
# db/migrate/[timestamp]_create_evaluation_indicators.rb
class CreateEvaluationIndicators < ActiveRecord::Migration[8.1]
  def change
    create_table :evaluation_indicators, if_not_exists: true do |t|
      t.string :code, null: false
      t.text :name, null: false
      t.text :description
      t.integer :level, default: 1
      t.timestamps
    end

    add_index :evaluation_indicators, :code, unique: true, if_not_exists: true
    add_index :evaluation_indicators, :level, if_not_exists: true
  end
end
```

---

## Part 2: SubIndicator Design

### Database Schema

```sql
CREATE TABLE sub_indicators (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  evaluation_indicator_id BIGINT NOT NULL REFERENCES evaluation_indicators ON DELETE CASCADE,
  code VARCHAR(100),
  name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(evaluation_indicator_id, code)
);

CREATE INDEX idx_sub_indicators_indicator_id ON sub_indicators(evaluation_indicator_id);
CREATE INDEX idx_sub_indicators_code ON sub_indicators(code);
```

### Model Implementation

```ruby
# app/models/sub_indicator.rb
class SubIndicator < ApplicationRecord
  belongs_to :evaluation_indicator
  has_many :items, dependent: :nullify

  validates :evaluation_indicator_id, presence: true
  validates :code, length: { maximum: 100 }, uniqueness: { scope: :evaluation_indicator_id }, allow_nil: true
  validates :name, presence: true, length: { minimum: 5, maximum: 500 }
  validates :description, length: { maximum: 2000 }, allow_nil: true

  validate :sub_indicator_requires_evaluation_indicator, if: :sub_indicator_id_changed?

  scope :by_indicator, ->(indicator_id) { where(evaluation_indicator_id: indicator_id) }
  scope :by_code_pattern, ->(pattern) { where('code ILIKE ?', "%#{pattern}%") }
  scope :with_items, -> { where.not(id: Item.where(sub_indicator_id: nil).select(:sub_indicator_id).distinct) }

  before_save :normalize_code

  class << self
    def search_by_indicator_and_name(indicator_id, query)
      by_indicator(indicator_id)
        .where('name ILIKE ? OR description ILIKE ? OR code ILIKE ?',
               "%#{query}%", "%#{query}%", "%#{query}%")
    end

    def import_for_indicator(indicator_id, sub_data)
      transaction do
        sub_data.each do |data|
          find_or_create_by!(
            evaluation_indicator_id: indicator_id,
            code: data[:code]
          ) do |sub|
            sub.name = data[:name]
            sub.description = data[:description]
          end
        end
      end
    end
  end

  def full_name
    code.present? ? "#{code}: #{name}" : name
  end

  def evaluation_indicator_name
    evaluation_indicator.name
  end

  def item_count
    items.count
  end

  def to_s
    full_name
  end

  private

  def normalize_code
    self.code = code.strip.upcase if code.present?
  end
end
```

### Migration

```ruby
# db/migrate/[timestamp]_create_sub_indicators.rb
class CreateSubIndicators < ActiveRecord::Migration[8.1]
  def change
    create_table :sub_indicators, if_not_exists: true do |t|
      t.references :evaluation_indicator,
                   null: false,
                   foreign_key: { on_delete: :cascade },
                   if_not_exists: true
      t.string :code
      t.text :name, null: false
      t.text :description
      t.timestamps
    end

    add_index :sub_indicators, :evaluation_indicator_id, if_not_exists: true
    add_index :sub_indicators, :code, if_not_exists: true
    add_index :sub_indicators,
              [:evaluation_indicator_id, :code],
              unique: true,
              if_not_exists: true
  end
end
```

---

## Part 3: Item Model Modifications

### Migration

```ruby
# db/migrate/[timestamp]_add_indicator_references_to_items.rb
class AddIndicatorReferencesToItems < ActiveRecord::Migration[8.1]
  def change
    unless column_exists?(:items, :evaluation_indicator_id)
      add_reference :items, :evaluation_indicator,
                    foreign_key: true,
                    null: true,
                    if_not_exists: true
    end

    unless column_exists?(:items, :sub_indicator_id)
      add_reference :items, :sub_indicator,
                    foreign_key: true,
                    null: true,
                    if_not_exists: true
    end

    unless index_exists?(:items, :evaluation_indicator_id)
      add_index :items, :evaluation_indicator_id
    end

    unless index_exists?(:items, :sub_indicator_id)
      add_index :items, :sub_indicator_id
    end

    unless index_exists?(:items, [:evaluation_indicator_id, :sub_indicator_id])
      add_index :items, [:evaluation_indicator_id, :sub_indicator_id]
    end
  end
end
```

### Updated Item Model (Excerpt)

```ruby
# app/models/item.rb - ADD to existing model:

class Item < ApplicationRecord
  # New associations
  belongs_to :evaluation_indicator, optional: true
  belongs_to :sub_indicator, optional: true

  # New validations
  validate :sub_indicator_requires_evaluation_indicator, if: :sub_indicator_id_changed?

  # New scopes
  scope :by_evaluation_indicator, ->(indicator_id) { where(evaluation_indicator_id: indicator_id) }
  scope :by_sub_indicator, ->(sub_id) { where(sub_indicator_id: sub_id) }
  scope :with_standards, -> { includes(:evaluation_indicator, :sub_indicator) }
  scope :without_standards, -> { where(evaluation_indicator_id: nil) }
  scope :mapped_to_standards, -> { where.not(evaluation_indicator_id: nil) }

  # New instance methods
  def has_standards?
    evaluation_indicator_id.present?
  end

  def standards_mapping
    {
      evaluation_indicator: evaluation_indicator&.to_s,
      sub_indicator: sub_indicator&.to_s
    }
  end

  def indicator_code
    evaluation_indicator&.code || 'UNMAPPED'
  end

  private

  def sub_indicator_requires_evaluation_indicator
    if sub_indicator_id.present? && evaluation_indicator_id.blank?
      errors.add(:evaluation_indicator_id, 'must be provided when sub_indicator is set')
    end
  end
end
```

---

## Part 4: API /api/v1 Namespace Design

### Folder Structure

```
app/controllers/api/
└── v1/
    ├── base_controller.rb
    ├── evaluation_indicators_controller.rb
    ├── sub_indicators_controller.rb
    ├── items_controller.rb
    ├── concerns/
    │   ├── authentication.rb
    │   ├── error_handling.rb
    │   └── pagination.rb
    └── ...

app/errors/
└── api_error.rb
```

### Routes

```ruby
# config/routes.rb - ADD:

namespace :api do
  namespace :v1 do
    resources :evaluation_indicators, only: [:index, :show, :create, :update, :destroy] do
      resources :sub_indicators, only: [:index, :show, :create]
    end
    resources :sub_indicators, only: [:index, :show, :update, :destroy]
    resources :items, only: [:index, :show, :create, :update, :destroy]
    # ... more endpoints in future
  end
end
```

### API Endpoints (First 3)

#### 1. GET /api/v1/evaluation_indicators
List all evaluation indicators

**Response** (200 OK):
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "code": "KOR-001",
      "name": "Reading Comprehension",
      "level": 1,
      "item_count": 5,
      "sub_indicator_count": 2,
      "created_at": "2026-02-03T10:00:00Z"
    }
  ],
  "meta": {
    "page": 1,
    "per_page": 25,
    "total": 10,
    "total_pages": 1
  },
  "errors": null
}
```

#### 2. GET /api/v1/evaluation_indicators/:id
Get specific indicator with sub-indicators

**Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "id": 1,
    "code": "KOR-001",
    "name": "Reading Comprehension",
    "level": 1,
    "sub_indicators": [
      {
        "id": 10,
        "code": "KOR-001-A",
        "name": "Identify main idea",
        "item_count": 3
      }
    ]
  }
}
```

#### 3. POST /api/v1/evaluation_indicators
Create new indicator

**Request Body**:
```json
{
  "evaluation_indicator": {
    "code": "KOR-002",
    "name": "Writing Skills",
    "level": 1,
    "description": "Student can write clear sentences"
  }
}
```

**Response** (201 Created):
```json
{
  "success": true,
  "data": {
    "id": 11,
    "code": "KOR-002",
    "name": "Writing Skills",
    "level": 1,
    "item_count": 0
  }
}
```

---

## Implementation Sequence

### Week 1: Database + Models
1. Create evaluation_indicators migration
2. Create EvaluationIndicator model
3. Create sub_indicators migration
4. Create SubIndicator model
5. Create add_indicator_references_to_items migration
6. Update Item model
7. Run all migrations: `bin/rails db:migrate`

### Week 2: API Layer
1. Create BaseController + modules
2. Update routes.rb
3. Create EvaluationIndicatorsController
4. Create SubIndicatorsController
5. Update ItemsController
6. Test all endpoints

### Week 3: Testing + Documentation
1. Write model tests
2. Write controller tests
3. Update API_SPECIFICATION.md
4. Achieve >80% coverage

---

## Critical Success Factors

✅ **Database**: All migrations run without errors
✅ **Models**: Validations + relationships work correctly
✅ **API**: All endpoints return proper JSON responses
✅ **Tests**: >80% code coverage
✅ **Docs**: API endpoints documented with examples

---

## Rollback Strategy

If blockers occur:

```bash
# Rollback to previous state
bin/rails db:rollback STEP=3  # Remove all indicator changes

# This will:
# - Remove add_indicator_references_to_items
# - Remove sub_indicators table
# - Remove evaluation_indicators table
```

---

## Dependencies & Blockers

| Item | Depends On | Blocks |
|------|-----------|--------|
| EvaluationIndicator | None | SubIndicator, Item updates, API |
| SubIndicator | EvaluationIndicator | Item updates, API |
| Item updates | SubIndicator | API implementation |
| API namespace | All models | Phase 5+ implementation |

---

**Document Status**: ✅ READY FOR IMPLEMENTATION
**Approval Required**: None (autonomous implementation)
**Start Date**: 2026-02-03
**Target Completion**: 2026-02-24

---

*Generated by bkit development methodology - P0 Implementation Design*
