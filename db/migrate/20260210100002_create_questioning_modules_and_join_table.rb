# frozen_string_literal: true

class CreateQuestioningModulesAndJoinTable < ActiveRecord::Migration[8.1]
  def change
    create_table :questioning_modules do |t|
      t.references :reading_stimulus, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.string :level, null: false
      t.string :status, null: false, default: "draft"
      t.jsonb :discussion_guide, null: false, default: {}
      t.text :learning_objectives, array: true, null: false, default: []
      t.integer :estimated_minutes
      t.integer :student_questions_count, null: false, default: 0
      t.integer :sessions_count, null: false, default: 0
      t.references :created_by, foreign_key: { to_table: :teachers }, null: true
      t.timestamps
    end
    add_index :questioning_modules, :level
    add_index :questioning_modules, :status
    add_index :questioning_modules, [:level, :status]

    create_table :questioning_module_templates do |t|
      t.references :questioning_module, null: false, foreign_key: true
      t.references :questioning_template, null: false, foreign_key: true
      t.integer :stage, null: false
      t.integer :position, null: false, default: 0
      t.boolean :required, null: false, default: true
      t.timestamps
    end
    add_index :questioning_module_templates,
              [:questioning_module_id, :questioning_template_id],
              unique: true, name: "index_qmt_on_module_and_template"
    add_index :questioning_module_templates,
              [:questioning_module_id, :stage, :position],
              name: "index_qmt_on_module_stage_position"
  end
end
