module Admin
  module UsersHelper
    ROLE_LABELS = {
      "admin" => "관리자",
      "researcher" => "문항개발자",
      "diagnostic_teacher" => "진단교사",
      "teacher" => "담당교사",
      "school_admin" => "학교관리자",
      "parent" => "학부모",
      "student" => "학생"
    }.freeze

    def role_label(role)
      ROLE_LABELS[role] || role
    end

    def role_badge_class(role)
      "rp-badge--#{role}"
    end
  end
end
