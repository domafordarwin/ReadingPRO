class DiagnosticTeacher::NoticesController < ApplicationController
  layout "unified_portal"
  before_action -> { require_role_any(%w[diagnostic_teacher admin]) }
  before_action :set_role
  before_action :set_notice, only: %i[edit update destroy]

  def index
    @current_page = "notices"
    @notices = Notice.includes(:created_by).recent
    @search_query = params[:search].to_s.strip
    @status_filter = params[:status].to_s.strip

    if @search_query.present?
      @notices = @notices.where("title ILIKE ? OR content ILIKE ?", "%#{@search_query}%", "%#{@search_query}%")
    end

    case @status_filter
    when "active"
      @notices = @notices.active
    when "important"
      @notices = @notices.important
    end

    @notices = @notices.page(params[:page]).per(10)
  end

  def new
    @current_page = "notices"
    @notice = Notice.new(published_at: Time.current)
  end

  def create
    @current_page = "notices"
    @notice = Notice.new(notice_params)
    @notice.created_by = current_user

    if @notice.save
      flash[:notice] = "공지사항이 등록되었습니다."
      redirect_to diagnostic_teacher_notices_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @current_page = "notices"
  end

  def update
    @current_page = "notices"
    if @notice.update(notice_params)
      flash[:notice] = "공지사항이 수정되었습니다."
      redirect_to diagnostic_teacher_notices_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @notice.destroy
    flash[:notice] = "공지사항이 삭제되었습니다."
    redirect_to diagnostic_teacher_notices_path, status: :see_other
  end

  private

  def set_role
    @current_role = "teacher"
  end

  def set_notice
    @notice = Notice.find(params[:id])
  end

  def notice_params
    params.require(:notice).permit(:title, :content, :important, :published_at, :expires_at, target_roles: [])
  end
end
