# frozen_string_literal: true

class Parent < ApplicationRecord
  belongs_to :user

  validates :name, presence: true

end
