# frozen_string_literal: true

# 엑셀 임포트 시 동일 RPS번호가 두 학교에 존재하여 잘못된 학교 학생에게 배정된 데이터 수정
# shinlim.ms.kr(school_id=2) rps_0001~0010 → shinmyung.edu(school_id=1) rps_0001~0010으로 이전
class FixMisassignedStudentAttempts < ActiveRecord::Migration[8.1]
  def up
    # 신명중 진단지 (form_id=4)
    form_id = 4

    # 신림중 학교 (school_id=2), 신명중 학교 (school_id=1)
    wrong_school_id = 2
    correct_school_id = 1

    (1..10).each do |num|
      padded = num.to_s.rjust(4, "0")

      # 잘못 배정된 학생 (shinlim.ms.kr)
      wrong_user = User.find_by("LOWER(email) LIKE ?", "rps_#{padded}@shinlim.ms.kr")
      next unless wrong_user
      wrong_student = wrong_user.student
      next unless wrong_student

      # 올바른 학생 (shinmyung.edu)
      correct_user = User.find_by("LOWER(email) LIKE ?", "rps_#{padded}@shinmyung.edu")
      next unless correct_user
      correct_student = correct_user.student
      next unless correct_student

      # 잘못된 학생의 해당 진단지 attempt 찾기
      wrong_attempts = StudentAttempt.where(student_id: wrong_student.id, diagnostic_form_id: form_id)
      next if wrong_attempts.empty?

      wrong_attempts.each do |attempt|
        # 올바른 학생에게 이미 같은 attempt가 있으면 건너뜀
        next if StudentAttempt.exists?(student_id: correct_student.id, diagnostic_form_id: form_id)

        # attempt의 student_id 변경
        attempt.update_columns(student_id: correct_student.id)

        # DiagnosticAssignment 이전: 잘못된 학생 것 삭제, 올바른 학생 것 생성/업데이트
        DiagnosticAssignment.where(
          diagnostic_form_id: form_id,
          student_id: wrong_student.id
        ).delete_all

        unless DiagnosticAssignment.exists?(diagnostic_form_id: form_id, student_id: correct_student.id, status: "completed")
          assigner = User.find_by(role: "admin") || User.find_by(role: "researcher") || User.first
          next unless assigner

          DiagnosticAssignment.create!(
            diagnostic_form_id: form_id,
            student_id: correct_student.id,
            assigned_by: assigner,
            assigned_at: attempt.started_at || attempt.created_at,
            status: "completed"
          )
        end

        Rails.logger.info "[FixMisassigned] RPS_#{padded}: attempt #{attempt.id} moved from student #{wrong_student.id} to #{correct_student.id}"
      end
    end

    # rps_0011@shinmyung.edu의 cancelled assignment 수정
    student_11_user = User.find_by("LOWER(email) LIKE ?", "rps_0011@shinmyung.edu")
    if student_11_user&.student
      cancelled = DiagnosticAssignment.where(
        student_id: student_11_user.student.id,
        diagnostic_form_id: form_id,
        status: "cancelled"
      ).first
      cancelled&.update_columns(status: "completed")
      Rails.logger.info "[FixMisassigned] RPS_0011: assignment status fixed to completed" if cancelled
    end
  end

  def down
    # 되돌리기 불가 (데이터 보정)
  end
end
