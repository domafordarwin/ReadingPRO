class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.string :notification_type, null: false  # consultation_request_created, consultation_request_approved, consultation_request_rejected
      t.references :notifiable, polymorphic: true, null: false  # ConsultationRequest, 등
      t.text :message
      t.boolean :read, default: false
      t.datetime :read_at

      t.timestamps
    end

    add_index :notifications, [:user_id, :read], name: "index_notifications_on_user_id_and_read"
    add_index :notifications, [:user_id, :created_at], name: "index_notifications_on_user_id_and_created_at"
  end
end
