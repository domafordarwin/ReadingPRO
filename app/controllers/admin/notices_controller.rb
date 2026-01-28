module Admin
  class NoticesController < BaseController
    before_action :set_notice, only: %i[edit update destroy]

    def index
      @notices = Notice.includes(:created_by).recent

      # 검색 기능
      if params[:search].present?
        search_term = "%#{params[:search]}%"
        @notices = @notices.where("title ILIKE ? OR content ILIKE ?", search_term, search_term)
      end

      # 역할 필터
      if params[:role].present? && Notice::TARGET_ROLES.include?(params[:role])
        @notices = @notices.for_role(params[:role])
      end

      # 상태 필터
      case params[:status]
      when "active"
        @notices = @notices.active
      when "important"
        @notices = @notices.important
      end
    end

    def new
      @notice = Notice.new
      @notice.published_at = Time.current
    end

    def create
      @notice = Notice.new(notice_params)
      @notice.created_by = current_user

      if @notice.save
        flash[:notice] = "공지사항이 성공적으로 생성되었습니다."
        redirect_to admin_notices_path
      else
        flash.now[:alert] = "공지사항 생성에 실패했습니다: #{@notice.errors.full_messages.join(', ')}"
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @notice.update(notice_params)
        flash[:notice] = "공지사항이 성공적으로 수정되었습니다."
        redirect_to admin_notices_path
      else
        flash.now[:alert] = "공지사항 수정에 실패했습니다: #{@notice.errors.full_messages.join(', ')}"
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @notice.destroy
      flash[:notice] = "공지사항이 성공적으로 삭제되었습니다."
      redirect_to admin_notices_path
    end

    private

    def set_notice
      @notice = Notice.find(params[:id])
    end

    def notice_params
      params.require(:notice).permit(
        :title,
        :content,
        :important,
        :published_at,
        :expires_at,
        target_roles: []
      )
    end
  end
end
