# frozen_string_literal: true

class AddDiscussionFieldsToQuestioningSessions < ActiveRecord::Migration[8.1]
  def change
    add_column :questioning_sessions, :hypothesis_confirmed, :boolean, default: false
    add_column :questioning_sessions, :hypothesis_data, :jsonb, default: {}
    add_column :questioning_sessions, :discussion_summary, :text
  end
end
