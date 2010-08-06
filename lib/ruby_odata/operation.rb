module OData
  # Internally used helper class for storing operations called against the service.  This class shouldn't be used directly.
  class Operation
    attr_accessor :kind, :klass_name, :klass
    
    # Creates a new instance of the Operation class
    #
    # ==== Required Attributes
    # - kind: 				The operation type (Add, Update, or Delete)
    # - klass_name:		The name/type of the class to operate against
    # - klass:				The actual class
    def initialize(kind, klass_name, klass)
      @kind = kind
      @klass_name = klass_name
      @klass = klass
    end
  end
end