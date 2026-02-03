class AddBundleFieldsToReadingStimuliAndItems < ActiveRecord::Migration[8.1]
  def change
    # Step 1: Add columns without NOT NULL constraint
    add_column :reading_stimuli, :code, :string
    add_column :reading_stimuli, :item_codes, :text, array: true, default: []
    add_column :reading_stimuli, :bundle_metadata, :jsonb, default: {}, null: false
    add_column :reading_stimuli, :bundle_status, :string, default: 'draft', null: false

    add_column :items, :stimulus_code, :string

    # Step 2: Populate data for existing records
    reversible do |dir|
      dir.up do
        # Generate unique codes for existing reading_stimuli
        ReadingStimulus.reset_column_information
        Item.reset_column_information

        ReadingStimulus.find_each do |stimulus|
          code = "STIM_#{stimulus.id.to_s.rjust(6, '0')}"

          # Update item_codes array
          item_codes = Item.where(stimulus_id: stimulus.id).pluck(:code)

          # Calculate bundle_metadata
          items = Item.where(stimulus_id: stimulus.id)
          metadata = {
            mcq_count: items.where(item_type: 'mcq').count,
            constructed_count: items.where(item_type: 'constructed').count,
            total_count: items.count,
            key_concepts: extract_key_concepts(stimulus.title),
            difficulty_distribution: {
              easy: items.where(difficulty: 'easy').count,
              medium: items.where(difficulty: 'medium').count,
              hard: items.where(difficulty: 'hard').count
            },
            estimated_time_minutes: calculate_time(items)
          }

          stimulus.update_columns(
            code: code,
            item_codes: item_codes,
            bundle_metadata: metadata
          )
        end

        # Update stimulus_code for existing items
        Item.where.not(stimulus_id: nil).find_each do |item|
          stimulus = ReadingStimulus.find_by(id: item.stimulus_id)
          item.update_column(:stimulus_code, stimulus.code) if stimulus
        end
      end
    end

    # Step 3: Add constraints and indexes after data is populated
    change_column_null :reading_stimuli, :code, false
    add_index :reading_stimuli, :code, unique: true
    add_index :reading_stimuli, :item_codes, using: :gin
    add_index :reading_stimuli, :bundle_metadata, using: :gin
    add_index :reading_stimuli, :bundle_status
    add_index :items, :stimulus_code
  end

  private

  def extract_key_concepts(title)
    return [] if title.blank?
    title.split(/[,\s-]+/).reject(&:blank?).take(5)
  end

  def calculate_time(items)
    mcq_time = items.where(item_type: 'mcq').count * 2
    constructed_time = items.where(item_type: 'constructed').count * 5
    mcq_time + constructed_time
  end
end
