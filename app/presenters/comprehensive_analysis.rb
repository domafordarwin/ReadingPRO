# frozen_string_literal: true

class ComprehensiveAnalysis
  attr_reader :overall_summary, :comprehension_analysis, :improvement_areas

  def initialize(attempt, achievements)
    @attempt = attempt
    @achievements = achievements
    @overall_summary = generate_summary
    @comprehension_analysis = generate_analysis
    @improvement_areas = generate_improvement_areas
  end

  private

  def generate_summary
    return "분석을 준비 중입니다." if @achievements.blank?

    avg_accuracy = (@achievements.sum { |a| a.accuracy_rate } / @achievements.length).round(1)
    "#{@attempt.student&.name}님의 종합 정답률은 #{avg_accuracy}%입니다."
  end

  def generate_analysis
    return "분석을 준비 중입니다." if @achievements.blank?

    strongest = @achievements.max_by { |a| a.accuracy_rate }
    weakest = @achievements.min_by { |a| a.accuracy_rate }

    "강점: #{strongest&.evaluation_indicator&.name} (#{strongest.accuracy_rate}%), " \
    "개선영역: #{weakest&.evaluation_indicator&.name} (#{weakest.accuracy_rate}%)"
  end

  def generate_improvement_areas
    return nil if @achievements.blank?

    weak = @achievements.select { |a| a.accuracy_rate < 70 }
                        .sort_by(&:accuracy_rate)
    return nil if weak.empty?

    weak.map { |a| "#{a.evaluation_indicator&.name} (#{a.accuracy_rate}%)" }.join(", ")
  end
end
