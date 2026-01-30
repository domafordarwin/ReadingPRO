# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password

  enum role: { student: 'student', teacher: 'teacher', researcher: 'researcher', admin: 'admin', parent: 'parent' }

  has_one :student, dependent: :destroy
  has_one :teacher, dependent: :destroy
  has_one :parent, dependent: :destroy
  has_many :audit_logs, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :password_digest, presence: true
  validates :role, presence: true
end
