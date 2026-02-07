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
      redirect_to admin_announcements_path, status: :see_other
    end

    def toggle_active
      # Publish/unpublish announcement by setting published_at
      if @announcement.published_at.present?
        @announcement.update(published_at: nil)
        flash[:notice] = "알림이 비공개되었습니다."
      else
        @announcement.update(published_at: Time.current)
        flash[:notice] = "알림이 공개되었습니다."
      end
      redirect_to admin_announcements_path
    end

    private

    def set_announcement
      @announcement = Announcement.find(params[:id])
    end

    def announcement_params
      params.require(:announcement).permit(
        :title,
        :content,
        :priority,
        :published_at
      )
    end
  end
end
