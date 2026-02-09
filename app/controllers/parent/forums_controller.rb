# frozen_string_literal: true

class Parent::ForumsController < ApplicationController
  layout "unified_portal"
  before_action -> { require_role_any("parent", "school_admin") }
  before_action :set_role
  before_action :set_forum, only: [ :show, :edit, :update, :destroy, :close, :reopen ]
  before_action :authorize_forum_author, only: [ :edit, :update, :destroy, :reopen ]

  def index
    @current_page = "feedback"

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
    @current_page = "feedback"

    # 조회수 증가 (본인 글이 아닐 때만)
    @forum.increment_views! unless @forum.created_by_id == current_user&.id

    # 댓글 로드
    @comments = @forum.parent_forum_comments
                      .includes(:created_by)
                      .recent

    # 새 댓글 폼용 객체
    @new_comment = @forum.parent_forum_comments.build
  end

  def new
    @current_page = "feedback"
    @forum = ParentForum.new(created_by: current_user)
  end

  def create
    @current_page = "feedback"
    @forum = ParentForum.new(forum_params)
    @forum.created_by = current_user

    if @forum.save
      redirect_to parent_forum_path(@forum), notice: "게시글이 작성되었습니다."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @current_page = "feedback"
  end

  def update
    @current_page = "feedback"

    if @forum.update(forum_params)
      redirect_to parent_forum_path(@forum), notice: "게시글이 수정되었습니다."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @forum.destroy
    redirect_to parent_forums_path, notice: "게시글이 삭제되었습니다.", status: :see_other
  end

  def close
    if @forum.mark_as_closed!
      redirect_to parent_forum_path(@forum), notice: "게시글이 마감되었습니다."
    else
      redirect_to parent_forum_path(@forum), alert: "게시글 마감에 실패했습니다."
    end
  end

  def reopen
    if @forum.reopen!
      redirect_to parent_forum_path(@forum), notice: "게시글이 다시 열렸습니다."
    else
      redirect_to parent_forum_path(@forum), alert: "게시글 열기에 실패했습니다."
    end
  end

  private

  def set_role
    @current_role = "parent"
  end

  def set_forum
    @forum = ParentForum.find(params[:id])
  end

  def authorize_forum_author
    unless @forum.created_by_id == current_user.id
      redirect_to parent_forums_path, alert: "권한이 없습니다."
    end
  end

  def forum_params
    params.require(:parent_forum).permit(:title, :content, :category)
  end
end
