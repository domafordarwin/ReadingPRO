module ApplicationHelper
  # 현재 사용자의 역할에 맞는 활성 공지사항을 가져옵니다
  # TODO: Notice 모델이 새로운 스키마에서 제거되었습니다. Announcement 모델 사용으로 변경 필요
  def current_role_notices(limit: 5)
    [] # Notice 모델이 존재하지 않음
  end

  # 모든 활성 공지사항을 가져옵니다 (역할 필터링 포함)
  # TODO: Notice 모델이 새로운 스키마에서 제거되었습니다. Announcement 모델 사용으로 변경 필요
  def all_current_role_notices
    [] # Notice 모델이 존재하지 않음
  end
end
