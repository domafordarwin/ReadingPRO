class CreateConsultationRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :consultation_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.references :student, null: false, foreign_key: true
      t.string :category, null: false, default: 'other'
      t.datetime :scheduled_at, null: false
      t.text :content, null: false
      t.string :status, null: false, default: 'pending'
      t.text :teacher_response
      t.datetime :responded_at

      t.timestamps
    end

    add_index :consultation_requests, [:user_id, :student_id]
    add_index :consultation_requests, :status
    add_index :consultation_requests, :created_at
  end
end
