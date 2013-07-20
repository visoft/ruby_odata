module OData
  # Raised when a user attempts to do something that is not supported
  class NotSupportedError < StandardError; end
  # Raised when the service returns an error
  class ServiceError < StandardError; end
end