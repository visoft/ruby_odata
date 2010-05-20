module OData
	# Internally used helper class for building a dynamic class.  This class shouldn't be called directly.
	class ClassBuilder
		# Creates a new instance of the ClassBuilder class
		#
		# ==== Required Attributes
		# - klass_name: 	The name/type of the class to create
		# - methods:			The accessor methods to add to the class
		# - nav_props:		The accessor methods to add for navigation properties
		def initialize(klass_name, methods, nav_props)
			@klass_name = klass_name
			@methods = methods
			@nav_props = nav_props
		end
		
		# Returns a dynamically generated class definition based on the constructor parameters
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
		      
			Object.const_set(@klass_name, Class.new.extend(ActiveSupport::JSON))
		  @klass = @klass_name.constantize
 
			add_methods(@klass)
			add_nav_props(@klass)
			
		  return @klass
		end
		
		private
		def add_methods(klass)
			# Add metadata methods
			klass.send :define_method, :__metadata do
				instance_variable_get("@__metadata")
			end
			klass.send :define_method, :__metadata= do |value|
					instance_variable_set("@__metadata", value)
			end
		  klass.send :define_method, :as_json do |options|
				meta = '__metadata'
				vars = self.instance_values
				
				if !options.nil? && options[:type] == :add  && vars.has_key?(meta)
					vars.delete_if { |k,v| k != meta}
				else
					vars.delete(meta)
				end

				vars
			end
			
			
			# Add the methods that were passed in
			@methods.each do |method_name|
				klass.send :define_method, method_name do
					instance_variable_get("@#{method_name}")
				end
				klass.send :define_method, "#{method_name}=" do |value|
					instance_variable_set("@#{method_name}", value)
				end
			end
		end
		
		def add_nav_props(klass)
			@nav_props.each do |method_name|
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