class ErrorsController < ApplicationController
  layout "application"

  def not_found
    render "errors/not_found", status: :not_found
  end
end
