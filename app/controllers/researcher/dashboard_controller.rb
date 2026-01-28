class Researcher::DashboardController < ApplicationController
  layout "unified_portal"
  before_action -> { require_role("researcher") }
  before_action :set_role

  def index
    @current_page = "item_bank"
  end

  def evaluation
    @current_page = "sub_analysis"
  end

  def item_bank
    @current_page = "item_bank"
  end

  def legacy_db
    @current_page = "item_bank"
  end

  def diagnostic_eval
    @current_page = "scoring"
  end

  def passages
    @current_page = "stimulus_mgmt"
  end

  def item_create
    @current_page = "item_mgmt"
  end

  def prompts
    @current_page = "item_mgmt"
  end

  def books
    @current_page = "item_bank"
  end

  private

  def set_role
    @current_role = "developer"
  end
end
