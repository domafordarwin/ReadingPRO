# frozen_string_literal: true

class Researcher::EvaluationIndicatorsController < ApplicationController
  before_action :require_login
  before_action -> { require_role("researcher") }

  def create
    name = params[:name].to_s.strip
    if name.blank? || name.length < 3
      return render json: { error: "이름은 3자 이상이어야 합니다." }, status: :unprocessable_entity
    end

    existing = EvaluationIndicator.find_by(name: name)
    if existing
      return render json: { id: existing.id, name: existing.name }, status: :ok
    end

    code = "EI-#{SecureRandom.hex(3).upcase}"
    indicator = EvaluationIndicator.new(name: name, code: code, level: 1)

    if indicator.save
      render json: { id: indicator.id, name: indicator.name }, status: :created
    else
      render json: { error: indicator.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end
end
