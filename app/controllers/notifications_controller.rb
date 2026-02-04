# frozen_string_literal: true

class NotificationsController < ApplicationController
  layout "unified_portal"
  before_action :require_login

  def index
    @current_page = "notifications"

    @unread_count = current_user.notifications.unread.count
    @notifications = current_user.notifications.recent.page(params[:page]).per(20)
  end

  def show
    @notification = current_user.notifications.find(params[:id])
    @notification.mark_as_read! if @notification.unread?

    case @notification.notifiable_type
    when "ConsultationRequest"
      redirect_to diagnostic_teacher_consultation_request_path(@notification.notifiable)
    else
      redirect_to notifications_path
    end
  end

  def mark_as_read
    @notification = current_user.notifications.find(params[:id])
    @notification.mark_as_read!
    redirect_back fallback_location: notifications_path, notice: "알림이 읽음 처리되었습니다."
  end

  def mark_all_as_read
    current_user.notifications.unread.update_all(read: true, read_at: Time.current)
    redirect_back fallback_location: notifications_path, notice: "모든 알림이 읽음 처리되었습니다."
  end
end
