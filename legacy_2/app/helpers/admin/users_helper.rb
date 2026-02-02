module Admin
  module UsersHelper
    ROLE_LABELS = {
      "admin" => "관리자",
      "teacher" => "진단담당교사",
      "parent" => "학부모",
      "student" => "학생"
    }.freeze

    def role_label(role)
      ROLE_LABELS[role] || role
    end

    def role_badge_class(role)
      case role
      when "admin" then "rp-badge--admin"
      when "teacher" then "rp-badge--teacher"
      when "parent" then "rp-badge--parent"
      when "student" then "rp-badge--student"
      else "rp-badge--default"
      end
    end
  end
end
