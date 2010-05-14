module OData
	class Operation
		attr_accessor :kind, :klass_name, :klass
		
		def initialize(kind, klass_name, klass)
			@kind = kind
			@klass_name = klass_name
			@klass = klass
		end
	end
end