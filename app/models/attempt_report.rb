# frozen_string_literal: true

class AttemptReport < ApplicationRecord
  belongs_to :student_attempt
  belongs_to :generated_by, class_name: "User", optional: true

  enum :performance_level, { advanced: "advanced", proficient: "proficient", developing: "developing", beginning: "beginning" }

  REPORT_STATUSES = %w[none draft published].freeze
  SECTION_KEYS = %w[overall_summary area_analysis mcq_analysis constructed_analysis reader_tendency comprehensive_opinion learning_recommendations].freeze
  SECTION_TITLES = {
    "overall_summary" => "종합 개요",
    "area_analysis" => "영역별 분석",
    "mcq_analysis" => "객관식 분석",
    "constructed_analysis" => "서술형 분석",
    "reader_tendency" => "독자 성향 분석",
    "comprehensive_opinion" => "종합 의견",
    "learning_recommendations" => "학습 권고사항"
  }.freeze

  validates :student_attempt_id, uniqueness: true
  validates :report_status, inclusion: { in: REPORT_STATUSES }

  scope :with_report, -> { where.not(report_status: "none") }
  scope :drafts, -> { where(report_status: "draft") }
  scope :published_reports, -> { where(report_status: "published") }

  def comprehensive_report_generated?
    report_sections.present? && report_sections.keys.any?
  end

  def section(key)
    report_sections&.dig(key.to_s) || {}
  end

  def section_content(key)
    section(key)["content"].to_s
  end

  def section_data(key)
    section(key)["data"] || {}
  end

  def update_section(key, content:, data: nil)
    sections = (report_sections || {}).dup
    sections[key.to_s] ||= {}
    sections[key.to_s]["content"] = content
    sections[key.to_s]["title"] = SECTION_TITLES[key.to_s]
    sections[key.to_s]["data"] = data if data.present?
    update!(report_sections: sections)
  end

  def publish!
    update!(report_status: "published", published_at: Time.current, generated_at: Time.current)
  end

  def unpublish!
    update!(report_status: "draft", published_at: nil, generated_at: nil)
  end

  # 하위호환: 기존 코드에서 사용하는 status 메서드
  def status
    return report_status if report_status != "none"
    generated_at.present? ? "published" : "draft"
  end

  def published?
    report_status == "published" || generated_at.present?
  end
end
