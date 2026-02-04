# frozen_string_literal: true

class ReadingStimulus < ApplicationRecord
  include Versionable  # PaperTrail version tracking

  belongs_to :teacher, foreign_key: "created_by_id", optional: true
  has_many :items, foreign_key: "stimulus_id", dependent: :destroy

  # Validations
  validates :body, presence: true
  validates :code, presence: true, uniqueness: true
  validates :bundle_status, inclusion: { in: %w[draft active archived] }, allow_blank: true
  validates :grade_level, inclusion: { in: %w[elementary_low elementary_high middle_low middle_high] }, allow_blank: true

  # Bundle status enum-like behavior
  scope :draft, -> { where(bundle_status: "draft") }
  scope :active, -> { where(bundle_status: "active") }
  scope :archived, -> { where(bundle_status: "archived") }

  # Grade level scopes (학년별)
  # 초저: 초등 1-2학년, 초고: 초등 3-6학년, 중저: 중1-2학년, 중고: 중3-고등
  scope :elementary_low, -> { where(grade_level: "elementary_low") }
  scope :elementary_high, -> { where(grade_level: "elementary_high") }
  scope :middle_low, -> { where(grade_level: "middle_low") }
  scope :middle_high, -> { where(grade_level: "middle_high") }
  scope :with_grade_level, ->(level) { level.present? ? where(grade_level: level) : all }

  # Grade level labels (한국어)
  GRADE_LEVELS = {
    "elementary_low" => "초저 (초1-2)",
    "elementary_high" => "초고 (초3-6)",
    "middle_low" => "중저 (중1-2)",
    "middle_high" => "중고 (중3-고)"
  }.freeze

  # Grade level short labels
  GRADE_LEVEL_SHORT = {
    "elementary_low" => "초저",
    "elementary_high" => "초고",
    "middle_low" => "중저",
    "middle_high" => "중고"
  }.freeze

  # Grade level colors for badges
  GRADE_LEVEL_COLORS = {
    "elementary_low" => "#4CAF50",    # 녹색
    "elementary_high" => "#2196F3",   # 파란색
    "middle_low" => "#FF9800",        # 주황색
    "middle_high" => "#9C27B0"        # 보라색
  }.freeze

  # Generate code before validation if not present
  before_validation :generate_code, on: :create

  # Phase 3.4.1: Cache invalidation hooks
  # Invalidates HTTP caches whenever ReadingStimulus is created/updated/destroyed
  # Also invalidates fragment caches in _items_table.html.erb
  after_save :invalidate_stimulus_caches
  after_destroy :invalidate_stimulus_caches

  # Recalculate bundle metadata after items change
  def recalculate_bundle_metadata!
    items_relation = Item.where(stimulus_id: id)

    self.bundle_metadata = {
      mcq_count: items_relation.where(item_type: "mcq").count,
      constructed_count: items_relation.where(item_type: "constructed").count,
      total_count: items_relation.count,
      key_concepts: key_concepts.presence || extract_key_concepts_fallback,
      difficulty_distribution: {
        easy: items_relation.where(difficulty: "easy").count,
        medium: items_relation.where(difficulty: "medium").count,
        hard: items_relation.where(difficulty: "hard").count
      },
      estimated_time_minutes: calculate_estimated_time(items_relation)
    }

    self.item_codes = items_relation.pluck(:code)
    save!
  end

  # Check if bundle is complete (has at least one item)
  def bundle_complete?
    items.exists?
  end

  # Get MCQ count from metadata
  def mcq_count
    bundle_metadata["mcq_count"] || 0
  end

  # Get constructed count from metadata
  def constructed_count
    bundle_metadata["constructed_count"] || 0
  end

  # Get total count from metadata
  def total_count
    bundle_metadata["total_count"] || 0
  end

  # Get key concepts from metadata
  def key_concepts
    bundle_metadata["key_concepts"] || []
  end

  # Get estimated time from metadata
  def estimated_time_minutes
    bundle_metadata["estimated_time_minutes"] || 0
  end

  # Perform AI-based analysis and update metadata
  # Options:
  #   - type: :concepts, :difficulty, or :full (default: :full)
  #   - save: true/false (default: true)
  def analyze_with_ai!(type: :full, save: true)
    extractor = KeyConceptExtractorService.new(self)

    analysis = case type
               when :concepts then extractor.extract_concepts
               when :difficulty then extractor.analyze_difficulty
               else extractor.full_analysis
               end

    # Merge AI analysis into bundle_metadata
    self.bundle_metadata = (bundle_metadata || {}).merge(
      "ai_analysis" => analysis,
      "key_concepts" => analysis[:key_concepts] || extract_key_concepts_fallback,
      "main_topic" => analysis[:main_topic],
      "domain" => analysis[:domain],
      "difficulty_level" => analysis[:difficulty_level],
      "difficulty_score" => analysis[:difficulty_score],
      "target_grade" => analysis[:target_grade],
      "summary" => analysis[:summary],
      "analyzed_at" => Time.current.iso8601
    )

    save! if save
    analysis
  end

  # Get AI analysis results
  def ai_analysis
    bundle_metadata["ai_analysis"] || {}
  end

  # Check if AI analysis has been performed
  def ai_analyzed?
    bundle_metadata["analyzed_at"].present?
  end

  # Get difficulty level (from AI or default)
  def difficulty_level
    bundle_metadata["difficulty_level"] || "medium"
  end

  # Get difficulty score (1-10)
  def difficulty_score
    bundle_metadata["difficulty_score"] || 5
  end

  # Get target grade
  def target_grade
    bundle_metadata["target_grade"]
  end

  # Get domain/category
  def domain
    bundle_metadata["domain"] || "일반"
  end

  # Get main topic
  def main_topic
    bundle_metadata["main_topic"]
  end

  # Get AI-generated summary
  def ai_summary
    bundle_metadata["summary"]
  end

  # Get grade level label (한국어)
  def grade_level_label
    GRADE_LEVELS[grade_level] || "미지정"
  end

  # Get grade level short label
  def grade_level_short
    GRADE_LEVEL_SHORT[grade_level] || "미지정"
  end

  # Get grade level badge color
  def grade_level_color
    GRADE_LEVEL_COLORS[grade_level] || "#9E9E9E"
  end

  # Check if grade level is set
  def grade_level_set?
    grade_level.present?
  end

  # Duplicate the stimulus with all its items
  # Options:
  #   - include_items: true/false (default: true) - copy items as well
  #   - suffix: string (default: " (복제본)") - suffix for the title
  #   - copy_ai_analysis: true/false (default: false) - copy AI analysis data
  def duplicate(include_items: true, suffix: " (복제본)", copy_ai_analysis: false)
    new_stimulus = dup

    # Generate new code (will be auto-generated by before_validation callback)
    new_stimulus.code = nil
    new_stimulus.title = "#{title}#{suffix}" if title.present?
    new_stimulus.bundle_status = "draft"
    new_stimulus.created_at = nil
    new_stimulus.updated_at = nil

    # Reset metadata unless copying AI analysis
    unless copy_ai_analysis
      new_stimulus.bundle_metadata = {
        "mcq_count" => 0,
        "constructed_count" => 0,
        "total_count" => 0,
        "key_concepts" => [],
        "difficulty_distribution" => { "easy" => 0, "medium" => 0, "hard" => 0 },
        "estimated_time_minutes" => 0
      }
    end
    new_stimulus.item_codes = []

    if new_stimulus.save
      # Duplicate items if requested
      if include_items && items.any?
        items.includes(:item_choices, rubric: { rubric_criteria: :rubric_levels }).each do |item|
          new_item = item.duplicate(stimulus: new_stimulus)
          unless new_item&.persisted?
            Rails.logger.error "[Stimulus#duplicate] Failed to duplicate item #{item.id}"
          end
        end

        # Recalculate metadata after copying items
        new_stimulus.recalculate_bundle_metadata!
      end

      new_stimulus
    else
      Rails.logger.error "[Stimulus#duplicate] Failed to save: #{new_stimulus.errors.full_messages}"
      nil
    end
  end

  private

  # Generate unique stimulus code
  def generate_code
    return if code.present?

    timestamp = Time.now.to_i
    random = SecureRandom.hex(4).upcase
    self.code = "STIM_#{timestamp}_#{random}"
  end

  # Extract key concepts from title and body (fallback method)
  def extract_key_concepts_fallback
    return [] if title.blank?
    concepts = title.split(/[,\s\-–—]+/).reject(&:blank?).take(5)
    concepts.reject { |c| c.length < 2 }
  end

  # Calculate estimated time based on item types
  # MCQ: 2 minutes, Constructed: 5 minutes
  def calculate_estimated_time(items_relation)
    mcq_time = items_relation.where(item_type: "mcq").count * 2
    constructed_time = items_relation.where(item_type: "constructed").count * 5
    mcq_time + constructed_time
  end

  # Invalidate HTTP response caches and fragment caches
  def invalidate_stimulus_caches
    CacheWarmerService.invalidate_stimulus_caches
    # Fragment caches will also be invalidated through Item cache_key dependency
  end
end
