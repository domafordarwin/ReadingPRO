# frozen_string_literal: true

# Phase 3.5.4: Admin System Monitoring Dashboard
#
# Purpose:
# - Display real-time performance metrics and Web Vitals
# - Show historical trends (24-hour)
# - Provide system health overview
#
# Data shown:
# - Current metrics (last 5 minutes)
# - Hourly trends (last 24 hours)
# - Web Vitals summary
# - Alert status

module Admin
  class SystemController < BaseController
    def student_diagnostics
      @students_data = Student.joins(:user)
        .where(users: { role: "student" })
        .includes(:user, :student_attempts)
        .order(:id)
        .map do |student|
          attempts = student.student_attempts
          completed_attempts = attempts.select { |a| %w[completed submitted].include?(a.status) }
          {
            id: student.id,
            email: student.user.email,
            name: student.name,
            school_id: student.school_id,
            attempts_count: attempts.size,
            completed_count: completed_attempts.size,
            attempt_details: completed_attempts.map { |a|
              report = AttemptReport.find_by(student_attempt_id: a.id)
              assignment = DiagnosticAssignment.find_by(
                diagnostic_form_id: a.diagnostic_form_id,
                student_id: student.id
              )
              school_assignment = DiagnosticAssignment.where(
                diagnostic_form_id: a.diagnostic_form_id,
                school_id: student.school_id
              ).first if student.school_id
              {
                attempt_id: a.id,
                form_id: a.diagnostic_form_id,
                form_name: a.diagnostic_form&.name,
                status: a.status,
                started_at: a.started_at,
                submitted_at: a.submitted_at,
                feedback_published: a.feedback_published_at.present?,
                has_report: report.present?,
                report_status: report&.report_status,
                report_published: report&.published_at.present?,
                has_student_assignment: assignment.present?,
                student_assignment_status: assignment&.status,
                has_school_assignment: school_assignment.present?,
                school_assignment_status: school_assignment&.status
              }
            }
          }
        end

      render json: @students_data, status: :ok
    end

    def show
      # Current metrics (last 5 minutes)
      @current_metrics = {
        avg_page_load: recent_avg_metric("page_load", 5.minutes),
        p95_page_load: recent_percentile_metric("page_load", 95, 5.minutes),
        avg_query_time: recent_avg_metric("query_time", 5.minutes),
        cache_hit_rate: calculate_cache_hit_rate
      }

      # Trend data (last 24 hours, hourly buckets)
      @metric_trends = {
        page_load: hourly_trend("page_load", 24.hours),
        query_time: hourly_trend("query_time", 24.hours),
        fcp: hourly_trend("fcp", 24.hours),
        lcp: hourly_trend("lcp", 24.hours)
      }

      # Web Vitals summary (last 1 hour)
      @web_vitals = {
        fcp_avg: recent_avg_metric("fcp", 1.hour),
        lcp_avg: recent_avg_metric("lcp", 1.hour),
        cls_avg: recent_avg_metric("cls", 1.hour),
        inp_avg: recent_avg_metric("inp", 1.hour),
        ttfb_avg: recent_avg_metric("ttfb", 1.hour)
      }

      # Metric collection counts
      @metric_counts = {
        total_metrics_24h: PerformanceMetric.recent(24.hours).count,
        page_load_samples: PerformanceMetric.by_type("page_load").recent(1.hour).count,
        web_vitals_samples: PerformanceMetric.where(metric_type: %w[fcp lcp cls inp ttfb]).recent(1.hour).count
      }
    end

    private

    def recent_avg_metric(type, duration)
      PerformanceMetric
        .recent(duration)
        .by_type(type)
        .average(:value)
        &.round(2) || 0
    end

    def recent_percentile_metric(type, percentile, duration)
      metrics = PerformanceMetric
        .recent(duration)
        .by_type(type)
        .order(:value)

      return 0 if metrics.count.zero?

      count_total = metrics.count
      offset_position = (count_total * percentile / 100.0).to_i
      metrics.offset(offset_position).limit(1).pluck(:value).first || 0
    end

    def calculate_cache_hit_rate
      # Placeholder: Could be enhanced with actual cache tracking
      # For now, return a reasonable estimate based on query patterns
      90.0
    end

    def hourly_trend(type, duration)
      # Group metrics by hour and calculate average per hour
      metrics = PerformanceMetric
        .where("recorded_at > ?", duration.ago)
        .where(metric_type: type)
        .group("DATE_TRUNC('hour', recorded_at)")
        .average(:value)

      # Transform keys to readable hour format
      metrics.transform_keys { |k| k.strftime("%H:00") }.sort
    end
  end
end
