class FeedbackPrompt < ApplicationRecord
  CATEGORIES = %w[
    comprehension explanation difficulty strategy general
    report_overview mcq_correct_analysis mcq_incorrect_analysis
    mcq_no_response_analysis constructed_analysis score_analysis
    reader_tendency_analysis reader_tendency_guidance
    comprehensive_literacy_analysis teaching_direction
  ].freeze

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
    when 'report_overview' then '진단 개요'
    when 'mcq_correct_analysis' then '객관식 정답 분석'
    when 'mcq_incorrect_analysis' then '객관식 오답 분석'
    when 'mcq_no_response_analysis' then '객관식 미응답 분석'
    when 'constructed_analysis' then '서술형 분석'
    when 'score_analysis' then '정답률 분석'
    when 'reader_tendency_analysis' then '독자 성향 분석'
    when 'reader_tendency_guidance' then '독자 성향 제언'
    when 'comprehensive_literacy_analysis' then '문해력 종합 분석'
    when 'teaching_direction' then '지도 방향'
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
