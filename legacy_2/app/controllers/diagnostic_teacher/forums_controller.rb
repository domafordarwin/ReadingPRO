# frozen_string_literal: true

class DiagnosticTeacher::ForumsController < ApplicationController
  layout "unified_portal"
  before_action -> { require_role("diagnostic_teacher") }
  before_action :set_role
  before_action :set_forum, only: [ :show ]

  def index
    @current_page = "forums"

    # 검색 및 필터링 파라미터
    @search_query = params[:search].to_s.strip
    @category_filter = params[:category].presence
    @status_filter = params[:status].presence

    # 모든 부모 게시글 조회
    @posts = ParentForum.all

    # 필터 적용
    @posts = @posts.search(@search_query) if @search_query.present?
    @posts = @posts.by_category(@category_filter) if @category_filter.present?
    @posts = @posts.where(status: @status_filter) if @status_filter.present?

    # 정렬 및 페이지네이션
    @posts = @posts.includes(:created_by, :parent_forum_comments)
                   .recent
                   .page(params[:page])
                   .per(20)

    # 통계 데이터
    @total_posts_count = ParentForum.count
    @open_posts_count = ParentForum.open_posts.count
    @answered_posts_count = ParentForum.answered_posts.count
  end

  def show
    @current_page = "forums"

    # 댓글 로드
    @comments = @forum.parent_forum_comments
                      .includes(:created_by)
                      .recent

    # 새 댓글 폼용 객체
    @new_comment = @forum.parent_forum_comments.build
  end

  private

  def set_role
    @current_role = "teacher"
  end

  def set_forum
    @forum = ParentForum.find(params[:id])
  end
end
