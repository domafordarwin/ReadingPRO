module Admin
  class BaseController < ApplicationController
    layout "admin"
    helper Admin::NavigationHelper
    before_action -> { require_role("admin") }
  end
end
