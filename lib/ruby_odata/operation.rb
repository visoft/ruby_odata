module OData
  # Internally used helper class for storing operations called against the service.  This class shouldn't be used directly.
  class Operation
    attr_accessor :kind, :klass_name, :klass, :child_klass
    
    # Creates a new instance of the Operation class
    #
    # ==== Required Attributes
    # - kind:         The operation type (Standard: Add, Update, or Delete | Links: AddLink)
    # - klass_name:   The name/type of the class to operate against
    # - klass:        The actual class
    # - child_klass:  (Optional) Only used for link operations
    def initialize(kind, klass_name, klass, child_klass = nil)
      @kind = kind
      @klass_name = klass_name
      @klass = klass
      @child_klass = child_klass
    end
  end
end