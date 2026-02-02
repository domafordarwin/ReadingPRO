# frozen_string_literal: true

class DiagnosticTeacher::ConsultationsController < ApplicationController
  layout "unified_portal"
  before_action -> { require_role("diagnostic_teacher") }
  before_action :set_role
  before_action :set_consultation_post, only: [:show, :mark_as_answered]

  def index
    @current_page = "consultations"

    # 검색 및 필터링
    @search_query = params[:search].to_s.strip
    @category_filter = params[:category].presence
    @status_filter = params[:status].presence
    @student_filter = params[:student_id].presence

    # 진단담당교사는 모든 상담글 조회 가능
    @posts = ConsultationPost.all

    # 필터 적용
    @posts = @posts.search(@search_query) if @search_query.present?
    @posts = @posts.by_category(@category_filter) if @category_filter.present?
    @posts = @posts.where(status: @status_filter) if @status_filter.present?
    @posts = @posts.by_student(@student_filter) if @student_filter.present?

    # 정렬 및 페이지네이션
    @posts = @posts.includes(:student, :created_by, :consultation_comments)
                   .recent
                   .page(params[:page])
                   .per(20)

    # 통계 데이터
    @total_posts = ConsultationPost.count
    @open_posts_count = ConsultationPost.open_posts.count
    @private_posts_count = ConsultationPost.private_posts.count
    @needs_reply_count = ConsultationPost.open_posts.where.missing(:consultation_comments).count
  end

  def show
    @current_page = "consultations"

    # 댓글 로드
    @comments = @post.consultation_comments
                     .includes(:created_by)
                     .recent

    # 새 댓글 폼용 객체
    @new_comment = @post.consultation_comments.build
  end

  def mark_as_answered
    if @post.mark_as_answered!
      redirect_to diagnostic_teacher_consultation_path(@post), notice: "답변 완료로 표시되었습니다."
    else
      redirect_to diagnostic_teacher_consultation_path(@post), alert: "상태 변경에 실패했습니다."
    end
  end

  private

  def set_role
    @current_role = "teacher"
  end

  def set_consultation_post
    @post = ConsultationPost.find(params[:id])
  end
end
