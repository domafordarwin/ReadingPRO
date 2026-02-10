# frozen_string_literal: true

# 기존 RPS_/RPP_ 형식 학생·학부모 ID를 학교도메인 기반 형식으로 변환
# rps_0001@shinmyung.edu → shinmyung_s-0001@shinmyung.edu
# RPS_0001 → shinmyung_S-0001
# rpp_0001@shinmyung.edu → shinmyung_p-0001@shinmyung.edu
# RPP_0001 → shinmyung_P-0001
class RenameStudentParentIdsToSchoolPrefix < ActiveRecord::Migration[8.0]
  def up
    School.find_each do |school|
      next unless school.email_domain.present?
      domain = school.email_domain
      prefix = domain.split(".").first # shinmyung.edu → shinmyung

      rename_students(school, domain, prefix)
      rename_parents(school, domain, prefix)
    end
  end

  def down
    # 역방향 변환: school_prefix 형식 → rps_/rpp_ 형식
    School.find_each do |school|
      next unless school.email_domain.present?
      domain = school.email_domain
      prefix = domain.split(".").first

      # Students: shinmyung_S-0001 → RPS_0001, shinmyung_s-0001@domain → rps_0001@domain
      school.students.where("name LIKE ?", "#{prefix}_S-%").find_each do |student|
        seq = student.name.match(/_S-(\d+)\z/)&.captures&.first
        next unless seq
        old_name = "RPS_#{seq}"
        old_email = "rps_#{seq}@#{domain}"
        student.update_columns(name: old_name, student_number: old_name)
        student.user&.update_columns(email: old_email) if student.user
      end

      # Parents
      Parent.joins(guardian_students: :student)
            .where(students: { school_id: school.id })
            .where("parents.name LIKE ?", "#{prefix}_P-%")
            .distinct.find_each do |parent|
        seq = parent.name.match(/_P-(\d+)\z/)&.captures&.first
        next unless seq
        old_name = "RPP_#{seq}"
        old_email = "rpp_#{seq}@#{domain}"
        parent.update_columns(name: old_name)
        parent.user&.update_columns(email: old_email) if parent.user
      end
    end
  end

  private

  def rename_students(school, domain, prefix)
    # RPS_XXXX 형식의 학생명을 가진 학생 검색
    school.students.where("name LIKE 'RPS_%'").find_each do |student|
      seq = student.name.match(/\ARPS_(\d+)\z/)&.captures&.first
      next unless seq

      new_name = "#{prefix}_S-#{seq}"
      new_email = "#{prefix}_s-#{seq}@#{domain}"

      # 이름/학번 변경
      student.update_columns(name: new_name, student_number: new_name)

      # User 이메일 변경 (중복 체크)
      user = student.user
      if user && !User.where(email: new_email).where.not(id: user.id).exists?
        user.update_columns(email: new_email)
        say "  Student: #{user.email_was rescue 'rps_' + seq + '@' + domain} → #{new_email}"
      end
    end
  end

  def rename_parents(school, domain, prefix)
    # 이 학교 학생과 연결된 학부모 중 RPP_ 형식인 것만 변환
    parent_ids = GuardianStudent.joins(:student)
                                .where(students: { school_id: school.id })
                                .pluck(:parent_id).uniq

    Parent.where(id: parent_ids).where("name LIKE 'RPP_%'").find_each do |parent|
      seq = parent.name.match(/\ARPP_(\d+)\z/)&.captures&.first
      next unless seq

      new_name = "#{prefix}_P-#{seq}"
      new_email = "#{prefix}_p-#{seq}@#{domain}"

      parent.update_columns(name: new_name)

      user = parent.user
      if user && !User.where(email: new_email).where.not(id: user.id).exists?
        user.update_columns(email: new_email)
        say "  Parent: #{user.email_was rescue 'rpp_' + seq + '@' + domain} → #{new_email}"
      end
    end
  end
end
