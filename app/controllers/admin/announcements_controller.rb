module Admin
  class AnnouncementsController < BaseController
    before_action :set_announcement, only: %i[edit update destroy toggle_active]

    def index
      @announcements = Announcement.ordered
    end

    def new
      @announcement = Announcement.new
    end

    def create
      @announcement = Announcement.new(announcement_params)

      if @announcement.save
        flash[:notice] = "랜딩 페이지 알림이 성공적으로 생성되었습니다."
        redirect_to admin_announcements_path
      else
        flash.now[:alert] = "알림 생성에 실패했습니다: #{@announcement.errors.full_messages.join(', ')}"
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @announcement.update(announcement_params)
        flash[:notice] = "알림이 성공적으로 수정되었습니다."
        redirect_to admin_announcements_path
      else
        flash.now[:alert] = "알림 수정에 실패했습니다: #{@announcement.errors.full_messages.join(', ')}"
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @announcement.destroy
      flash[:notice] = "알림이 성공적으로 삭제되었습니다."
      redirect_to admin_announcements_path
    end

    def toggle_active
      @announcement.update(active: !@announcement.active)
      flash[:notice] = "알림 상태가 변경되었습니다."
      redirect_to admin_announcements_path
    end

    private

    def set_announcement
      @announcement = Announcement.find(params[:id])
    end

    def announcement_params
      params.require(:announcement).permit(
        :content,
        :link_url,
        :link_text,
        :active,
        :display_order
      )
    end
  end
end
