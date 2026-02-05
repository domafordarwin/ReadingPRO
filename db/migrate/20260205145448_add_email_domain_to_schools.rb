# frozen_string_literal: true

class AddEmailDomainToSchools < ActiveRecord::Migration[8.1]
  def change
    add_column :schools, :email_domain, :string

    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE schools SET email_domain = 'school.edu' WHERE email_domain IS NULL
        SQL
      end
    end
  end
end
