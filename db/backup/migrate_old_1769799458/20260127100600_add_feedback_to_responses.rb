class AddFeedbackToResponses < ActiveRecord::Migration[8.1]
  def change
    add_column :responses, :is_correct, :boolean
    add_column :responses, :feedback, :text
    add_column :responses, :evaluation_grade, :string  # 적절, 보완필요, 부족, 미응답
    add_column :responses, :strengths, :text
  end
end
