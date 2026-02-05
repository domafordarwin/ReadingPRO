# frozen_string_literal: true

class DiagnosticTeacher::SchoolsController < ApplicationController
  layout "unified_portal"
  before_action -> { require_role_any(%w[diagnostic_teacher teacher]) }
  before_action :set_role

  def new
    @current_page = "managers"
    @school = School.new
  end

  def create
    @current_page = "managers"

    ActiveRecord::Base.transaction do
      # 학교 생성
      @school = School.new(school_params)
      unless @school.save
        render :new, status: :unprocessable_entity
        return
      end

      # 학교 관리자(school_admin) 계정 자동 생성
      temp_password = generate_temp_password
      @admin_user = User.new(
        email: params[:admin_email],
        password: temp_password,
        password_confirmation: temp_password,
        role: "school_admin",
        must_change_password: true
      )

      unless @admin_user.save
        @school.errors.add(:base, "관리자 계정 생성 실패: #{@admin_user.errors.full_messages.join(', ')}")
        raise ActiveRecord::Rollback
      end

      # 학교 포트폴리오 생성
      SchoolPortfolio.create!(school: @school, total_students: 0, total_attempts: 0, average_score: 0)

      flash[:notice] = "학교 '#{@school.name}'이(가) 생성되었습니다."
      flash[:temp_password] = temp_password
      flash[:admin_email] = @admin_user.email
      redirect_to diagnostic_teacher_managers_path
      return
    end

    # 트랜잭션 롤백 시
    render :new, status: :unprocessable_entity
  end

  private

  def set_role
    @current_role = "teacher"
  end

  def school_params
    params.require(:school).permit(:name, :region, :district, :email_domain)
  end

  def generate_temp_password
    "RP#{SecureRandom.alphanumeric(8)}!"
  end
end
