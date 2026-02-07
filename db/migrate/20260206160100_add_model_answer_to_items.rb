class AddModelAnswerToItems < ActiveRecord::Migration[8.1]
  def change
    add_column :items, :model_answer, :text
  end
end
