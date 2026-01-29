class FeedbackPrompt < ApplicationRecord
  CATEGORIES = %w[comprehension explanation difficulty strategy general].freeze

  belongs_to :response, optional: true
  belongs_to :user
  has_many :feedback_prompt_histories, dependent: :destroy

  validates :prompt_text, presence: true
  validates :category, presence: true, inclusion: { in: CATEGORIES }

  scope :templates, -> { where(is_template: true) }
  scope :custom, -> { where(is_template: false) }
  scope :by_category, ->(cat) { where(category: cat) if cat.present? }
  scope :recent, -> { order(created_at: :desc) }

  def category_label
    case category
    when 'comprehension' then '이해력'
    when 'explanation' then '설명'
    when 'difficulty' then '난이도'
    when 'strategy' then '전략'
    when 'general' then '일반'
    else category
    end
  end

  # 템플릿 찾거나 생성 (중복 방지)
  def self.find_or_create_template(prompt_text:, category:, user:)
    template = templates.find_by(prompt_text: prompt_text, category: category)

    if template
      template
    else
      create!(
        prompt_text: prompt_text,
        category: category,
        user: user,
        is_template: true
      )
    end
  end
end
