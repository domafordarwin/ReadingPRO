class CreateItemBankCore < ActiveRecord::Migration[8.1]
  def change
    create_table :stimuli do |t|
      t.string :code
      t.string :title
      t.text :body
      t.timestamps
    end
    add_index :stimuli, :code, unique: true

    create_table :items do |t|
      t.string :code, null: false
      t.string :item_type, null: false
      t.string :status, null: false
      t.string :difficulty
      t.text :prompt, null: false
      t.text :explanation
      t.references :stimulus, foreign_key: true
      t.jsonb :scoring_meta, null: false, default: {}
      t.timestamps
    end
    add_index :items, :code, unique: true

    create_table :item_choices do |t|
      t.references :item, null: false, foreign_key: true
      t.integer :choice_no, null: false
      t.text :content, null: false
      t.timestamps
    end
    add_index :item_choices, %i[item_id choice_no], unique: true

    create_table :choice_scores do |t|
      t.references :item_choice, null: false, foreign_key: true, index: { unique: true }
      t.integer :score_percent, null: false
      t.text :rationale
      t.boolean :is_key, null: false, default: false
      t.timestamps
    end
    add_check_constraint :choice_scores,
                         "score_percent >= 0 AND score_percent <= 100",
                         name: "choice_scores_score_percent_range"
  end
end
