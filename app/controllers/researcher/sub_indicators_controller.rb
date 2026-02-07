# frozen_string_literal: true

class Researcher::SubIndicatorsController < ApplicationController
  before_action :require_login
  before_action -> { require_role("researcher") }

  def create
    name = params[:name].to_s.strip
    evaluation_indicator_id = params[:evaluation_indicator_id]

    if name.blank? || name.length < 3
      return render json: { error: "이름은 3자 이상이어야 합니다." }, status: :unprocessable_entity
    end

    unless EvaluationIndicator.exists?(id: evaluation_indicator_id)
      return render json: { error: "평가영역을 먼저 선택하세요." }, status: :unprocessable_entity
    end

    existing = SubIndicator.find_by(evaluation_indicator_id: evaluation_indicator_id, name: name)
    if existing
      return render json: { id: existing.id, name: existing.name, evaluation_indicator_id: existing.evaluation_indicator_id }, status: :ok
    end

    sub = SubIndicator.new(name: name, evaluation_indicator_id: evaluation_indicator_id)

    if sub.save
      render json: { id: sub.id, name: sub.name, evaluation_indicator_id: sub.evaluation_indicator_id }, status: :created
    else
      render json: { error: sub.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end
end
