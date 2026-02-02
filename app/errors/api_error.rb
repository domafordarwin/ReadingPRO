# frozen_string_literal: true

class ApiError < StandardError
  class NotFound < ApiError; end
  class Unauthorized < ApiError; end
  class Forbidden < ApiError; end
  class ValidationError < ApiError; end
  class ConflictError < ApiError; end
end
