# frozen_string_literal: true

class Student::ConsultationsController < ApplicationController
  layout "unified_portal"
  before_action -> { require_role_any("student", "school_admin") }
  before_action :set_role
  before_action :set_student, only: [ :index, :show, :edit, :update, :destroy, :close, :reopen, :create ]
  before_action :set_consultation_post, only: [ :show, :edit, :update, :destroy, :close, :reopen ]
  before_action :authorize_consultation_post, only: [ :show, :edit, :update, :destroy, :close ]
  before_action :authorize_post_author, only: [ :reopen ]

  def index
    @current_page = "feedback"

    # 검색 및 필터링 파라미터
    @search_query = params[:search].to_s.strip
    @category_filter = params[:category].presence
    @visibility_filter = params[:visibility].presence
    @status_filter = params[:status].presence
    @show_my_posts = params[:my_posts] == "1"

    # 기본 쿼리: 학생 본인의 글 + 공개 글
    @posts = if @show_my_posts
               @student.consultation_posts
    else
               ::ConsultationPost.where("student_id = ? OR visibility = ?", @student.id, "public")
    end

    # 필터 적용
    @posts = @posts.search(@search_query) if @search_query.present?
    @posts = @posts.by_category(@category_filter) if @category_filter.present?
    @posts = @posts.where(visibility: @visibility_filter) if @visibility_filter.present?
    @posts = @posts.where(status: @status_filter) if @status_filter.present?

    # 정렬 및 페이지네이션
    @posts = @posts.includes(:student, :created_by, :consultation_comments)
                   .recent
                   .page(params[:page])
                   .per(20)

    # 통계 데이터
    @my_posts_count = @student.consultation_posts.count
    @open_posts_count = @student.consultation_posts.open_posts.count
    @answered_posts_count = @student.consultation_posts.answered_posts.count
  end

  def show
    @current_page = "feedback"

    # 조회수 증가 (본인 글이 아닐 때만)
    @post.increment_views! unless @post.created_by_id == current_user&.id

    # 댓글 로드
    @comments = @post.consultation_comments
                     .includes(:created_by)
                     .recent

    # 새 댓글 폼용 객체
    @new_comment = @post.consultation_comments.build
  end

  def new
    @current_page = "feedback"
    @post = @student.consultation_posts.build(created_by: current_user)
  end

  def create
    @current_page = "feedback"
    @post = @student.consultation_posts.build(consultation_post_params)
    @post.created_by = current_user

    if @post.save
      redirect_to student_consultation_path(@post), notice: "게시글이 작성되었습니다."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @current_page = "feedback"
  end

  def update
    @current_page = "feedback"

    if @post.update(consultation_post_params)
      redirect_to student_consultation_path(@post), notice: "게시글이 수정되었습니다."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy
    redirect_to student_consultations_path, notice: "게시글이 삭제되었습니다.", status: :see_other
  end

  def close
    if @post.mark_as_closed!
      redirect_to student_consultation_path(@post), notice: "게시글이 마감되었습니다."
    else
      redirect_to student_consultation_path(@post), alert: "게시글 마감에 실패했습니다."
    end
  end

  def reopen
    if @post.reopen!
      redirect_to student_consultation_path(@post), notice: "게시글이 다시 열렸습니다."
    else
      redirect_to student_consultation_path(@post), alert: "게시글 열기에 실패했습니다."
    end
  end

  private

  def set_role
    @current_role = "student"
  end

  def set_student
    @student = current_user&.student

    unless @student
      redirect_to student_dashboard_path, alert: "학생 정보를 찾을 수 없습니다."
    end
  end

  def set_consultation_post
    @post = ::ConsultationPost.find(params[:id])
  end

  def authorize_consultation_post
    unless @post.visible_to?(current_user)
      redirect_to student_consultations_path, alert: "접근 권한이 없습니다."
    end
  end

  def authorize_post_author
    unless @post.created_by_id == current_user.id
      redirect_to student_consultation_path(@post), alert: "권한이 없습니다."
    end
  end

  def consultation_post_params
    params.require(:consultation_post).permit(:title, :content, :category, :visibility)
  end
end
