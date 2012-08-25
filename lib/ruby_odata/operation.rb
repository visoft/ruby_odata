module OData
  # Internally used helper class for storing operations called against the service.  This class shouldn't be used directly.
  class Operation
    attr_accessor :kind, :klass_name, :klass, :child_klass

    # Creates a new instance of the Operation class
    #
    # @param [String] kind the operation type (Standard: Add, Update, or Delete | Links: AddLink)
    # @param [String] klass_name the name/type of the class to operate against
    # @param [Object] klass the actual class
    # @param [Object, nil] child_klass used for link operations only
    def initialize(kind, klass_name, klass, child_klass = nil)
      @kind = kind
      @klass_name = klass_name
      @klass = klass
      @child_klass = child_klass
    end
  end
end