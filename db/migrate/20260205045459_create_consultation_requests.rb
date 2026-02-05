class CreateConsultationRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :consultation_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.references :student, null: false, foreign_key: true
      t.string     :category, null: false, default: "academic"
      t.text       :content, null: false
      t.datetime   :scheduled_at
      t.string     :status, null: false, default: "pending"
      t.text       :teacher_response
      t.bigint     :responded_by_id
      t.datetime   :responded_at
      t.timestamps
    end

    add_index :consultation_requests, [:user_id, :student_id]
    add_index :consultation_requests, :status
    add_index :consultation_requests, :created_at

    create_table :consultation_request_responses do |t|
      t.references :consultation_request, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.text       :content, null: false
      t.timestamps
    end

    add_index :consultation_request_responses, :created_at
  end
end
