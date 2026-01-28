module Admin
  class BaseController < ApplicationController
    layout "admin"
    helper Admin::NavigationHelper
    helper Admin::BaseHelper
    before_action -> { require_role("admin") }
  end
end
