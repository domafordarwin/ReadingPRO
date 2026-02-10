# frozen_string_literal: true

# 엑셀 일괄 등록으로 StudentAttempt는 있지만 DiagnosticAssignment가 없는 경우 보정
class BackfillDiagnosticAssignmentsForImportedAttempts < ActiveRecord::Migration[8.1]
  def up
    admin_user = User.find_by(role: "admin")

    StudentAttempt.where(status: %w[completed submitted]).find_each do |attempt|
      student = attempt.student
      next unless student

      # 이미 completed 배정이 있으면 건너뜀
      next if DiagnosticAssignment.exists?(
        diagnostic_form_id: attempt.diagnostic_form_id,
        student_id: student.id,
        status: "completed"
      )

      # 기존 active 배정이 있으면 completed로 변경
      active_assignment = DiagnosticAssignment.where(
        diagnostic_form_id: attempt.diagnostic_form_id
      ).where(
        "student_id = ? OR school_id = ?", student.id, student.school_id
      ).where(status: %w[assigned in_progress]).first

      if active_assignment
        active_assignment.update!(status: "completed")
      else
        # 배정이 전혀 없으면 신규 생성
        DiagnosticAssignment.create!(
          diagnostic_form_id: attempt.diagnostic_form_id,
          student_id: student.id,
          assigned_by: admin_user,
          assigned_at: attempt.started_at || attempt.created_at,
          status: "completed"
        )
      end
    end
  end

  def down
    # 되돌리기 불가 (데이터 보정)
  end
end
