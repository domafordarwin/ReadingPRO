module Admin
  class UsersController < BaseController
    def index
      @users = User.all

      # 검색 기능 (이메일)
      if params[:search].present?
        search_term = "%#{params[:search]}%"
        @users = @users.where("email ILIKE :q", q: search_term)
      end

      # 역할 필터
      if params[:role].present? && User.roles.key?(params[:role])
        @users = @users.where(role: params[:role])
      end

      @users = @users.order(created_at: :desc)
    end

    def create
      @user = User.new(
        email: params[:email],
        role: params[:role],
        password: params[:password],
        password_confirmation: params[:password_confirmation]
      )

      if @user.save
        flash[:notice] = "사용자가 생성되었습니다: #{@user.email} (#{Admin::UsersHelper::ROLE_LABELS[@user.role] || @user.role})"
      else
        flash[:alert] = "사용자 생성에 실패했습니다: #{@user.errors.full_messages.join(', ')}"
      end

      redirect_to admin_users_path
    end

    def update_role
      @user = User.find(params[:id])

      if @user.update(role: params[:role])
        flash[:notice] = "역할이 성공적으로 변경되었습니다."
      else
        flash[:alert] = "역할 변경에 실패했습니다: #{@user.errors.full_messages.join(', ')}"
      end

      redirect_to admin_users_path
    end

    def reset_password
      @user = User.find(params[:id])
      new_password = params[:new_password] || generate_random_password

      if @user.update(password: new_password, password_confirmation: new_password)
        flash[:notice] = "비밀번호가 성공적으로 재설정되었습니다. 새 비밀번호: #{new_password}"
      else
        flash[:alert] = "비밀번호 재설정에 실패했습니다: #{@user.errors.full_messages.join(', ')}"
      end

      redirect_to admin_users_path
    end

    private

    def generate_random_password
      SecureRandom.alphanumeric(12)
    end
  end
end
