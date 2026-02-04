class AddGradeLevelToReadingStimuli < ActiveRecord::Migration[8.1]
  def change
    # 레벨 컬럼 추가: 초저(elementary_low), 초고(elementary_high), 중저(middle_low), 중고(middle_high)
    add_column :reading_stimuli, :grade_level, :string, default: nil

    # 레벨별 필터링을 위한 인덱스
    add_index :reading_stimuli, :grade_level, name: "idx_reading_stimuli_grade_level"
  end
end
