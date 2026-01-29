class CreateConsultationRequestResponses < ActiveRecord::Migration[8.1]
  def change
    create_table :consultation_request_responses do |t|
      t.references :consultation_request, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.text :content, null: false

      t.timestamps
    end

    add_index :consultation_request_responses, :created_at
  end
end
