# frozen_string_literal: true

class SchoolAdminProfile < ApplicationRecord
  self.table_name = "school_admins"

  belongs_to :user
  belongs_to :school

  validates :name, presence: true
  validates :user_id, uniqueness: true

  delegate :email, to: :user
end
