module OData
	# Internally used helper class for storing operations called against the service
	class Operation
		attr_accessor :kind, :klass_name, :klass
		
		def initialize(kind, klass_name, klass)
			@kind = kind
			@klass_name = klass_name
			@klass = klass
		end
	end
end