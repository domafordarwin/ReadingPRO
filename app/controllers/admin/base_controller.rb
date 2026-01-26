module Admin
  class BaseController < ApplicationController
    layout "admin"
    helper Admin::NavigationHelper
  end
end
