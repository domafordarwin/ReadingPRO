module ApplicationHelper
  # 현재 사용자의 역할에 맞는 활성 공지사항을 가져옵니다
  def current_role_notices(limit: 5)
    return [] unless current_role.present?

    Notice.active
          .for_role(current_role)
          .important
          .recent
          .limit(limit)
  end

  # 모든 활성 공지사항을 가져옵니다 (역할 필터링 포함)
  def all_current_role_notices
    return [] unless current_role.present?

    Notice.active
          .for_role(current_role)
          .recent
  end
end
