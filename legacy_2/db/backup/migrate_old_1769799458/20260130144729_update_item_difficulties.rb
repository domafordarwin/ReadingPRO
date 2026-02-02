class UpdateItemDifficulties < ActiveRecord::Migration[8.1]
  def change
    # Map old difficulty values to new ones
    # easy -> very_low
    # medium -> medium
    # hard -> high
    reversible do |dir|
      dir.up do
        execute "UPDATE items SET difficulty = 'very_low' WHERE difficulty = 'easy'"
        execute "UPDATE items SET difficulty = 'high' WHERE difficulty = 'hard'"
      end
      dir.down do
        execute "UPDATE items SET difficulty = 'easy' WHERE difficulty = 'very_low'"
        execute "UPDATE items SET difficulty = 'hard' WHERE difficulty = 'high'"
      end
    end
  end
end
