class SchoolAdmin::DashboardController < ApplicationController
  layout "unified_portal"
  before_action -> { require_role("school_admin") }
  before_action :set_role

  def index
    @current_page = "school_reports"
  end

  def students
    @current_page = "student_mgmt"
  end

  def diagnostics
    @current_page = "distribution"
  end

  def reports
    @current_page = "school_reports"
  end

  def report_template
    @current_page = "school_reports"
    @assessment = SchoolAssessment
                  .includes(
                    :school,
                    { school_literacy_stats: :evaluation_indicator },
                    { school_sub_indicator_stats: %i[evaluation_indicator sub_indicator] },
                    :school_reader_type_distributions,
                    :school_reader_type_recommendations,
                    :school_comprehensive_analysis,
                    { school_guidance_directions: %i[evaluation_indicator sub_indicator] },
                    :school_improvement_areas,
                    { school_mcq_analyses: %i[evaluation_indicator sub_indicator] },
                    { school_essay_analyses: %i[evaluation_indicator sub_indicator] }
                  )
                  .find_by(id: params[:assessment_id])
    @assessment ||= SchoolAssessment
                    .includes(
                      :school,
                      { school_literacy_stats: :evaluation_indicator },
                      { school_sub_indicator_stats: %i[evaluation_indicator sub_indicator] },
                      :school_reader_type_distributions,
                      :school_reader_type_recommendations,
                      :school_comprehensive_analysis,
                      { school_guidance_directions: %i[evaluation_indicator sub_indicator] },
                      :school_improvement_areas,
                      { school_mcq_analyses: %i[evaluation_indicator sub_indicator] },
                      { school_essay_analyses: %i[evaluation_indicator sub_indicator] }
                    )
                    .order(assessment_date: :desc)
                    .first
  end

  def about
    @current_page = "notice"
  end

  def managers
    @current_page = "student_mgmt"
  end

  private

  def set_role
    @current_role = "school_admin"
  end
end
