class AddCompositeIndexToConsultationPosts < ActiveRecord::Migration[8.1]
  def change
    add_index :consultation_posts, [ :student_id, :created_at ], name: "idx_on_consultation_posts_student_id_created_at"
  end
end
