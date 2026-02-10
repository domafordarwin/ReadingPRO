# frozen_string_literal: true

class AddFeedbackWorkflowToStudentQuestions < ActiveRecord::Migration[8.1]
  def change
    add_column :student_questions, :feedback_published_at, :datetime
    add_column :student_questions, :feedback_published_by_id, :bigint
    add_column :student_questions, :student_confirmed_at, :datetime

    add_index :student_questions, :feedback_published_at
    add_foreign_key :student_questions, :users, column: :feedback_published_by_id

    # 기존 데이터 백필: 이미 ai_score가 있는 질문은 자동 배포/확인 처리
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE student_questions
          SET feedback_published_at = NOW(),
              student_confirmed_at = NOW()
          WHERE ai_score IS NOT NULL
        SQL
      end
    end
  end
end
