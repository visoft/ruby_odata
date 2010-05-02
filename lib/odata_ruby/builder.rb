module OData
	class ClassBuilder
		def initialize(klass_name, methods)
			@klass_name = klass_name
			@methods = methods
		end
		
		def build
			# return if already built
		    return @klass unless @klass.nil?
		
		    # need the class name to build class
		    return nil    if @klass_name.nil?
		      
			# return if we can find constant corresponding to class name
			if Object.constants.include? @klass_name
				@klass = @klass_name.constantize
				return @klass
			end
		      
			Object.const_set(@klass_name, Class.new)
		    @klass = @klass_name.constantize
			add_methods(@klass)
		    return @klass
		end
		
		private
		def add_methods(klass)
			@methods.each do |method_name|
				klass.send :define_method, method_name do
					instance_variable_get("@#{method_name}")
				end
				klass.send :define_method, "#{method_name}=" do |value|
					instance_variable_set("@#{method_name}", value)
				end
			end
		end
	end
end # module OData