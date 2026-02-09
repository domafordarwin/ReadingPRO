# frozen_string_literal: true

class CreateQuestioningTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :questioning_templates do |t|
      t.references :evaluation_indicator, foreign_key: true, null: true
      t.references :sub_indicator, foreign_key: true, null: true
      t.integer :stage, null: false
      t.string :level, null: false
      t.string :template_type, null: false
      t.text :template_text, null: false
      t.integer :scaffolding_level, null: false, default: 0
      t.text :example_question
      t.text :guidance_text
      t.integer :sort_order, null: false, default: 0
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :questioning_templates, [:stage, :level]
    add_index :questioning_templates, :template_type
    add_index :questioning_templates, :scaffolding_level
    add_index :questioning_templates, :active
  end
end
