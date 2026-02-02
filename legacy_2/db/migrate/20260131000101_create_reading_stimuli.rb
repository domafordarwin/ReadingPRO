# frozen_string_literal: true

class CreateReadingStimuli < ActiveRecord::Migration[8.1]
  def change
    create_table :reading_stimuli do |t|
      t.string :title
      t.text :body, null: false
      t.string :source
      t.integer :word_count
      t.string :reading_level
      t.references :created_by, foreign_key: { to_table: :teachers }
      t.timestamps
    end

    add_index :reading_stimuli, :reading_level
  end
end
