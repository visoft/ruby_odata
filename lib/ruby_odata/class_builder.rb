module OData
  # Internally used helper class for building a dynamic class.  This class shouldn't be called directly.
  class ClassBuilder
    # Creates a new instance of the ClassBuilder class
    #
    # ==== Required Attributes
    # - klass_name:   The name/type of the class to create
    # - methods:      The accessor methods to add to the class
    # - nav_props:    The accessor methods to add for navigation properties
    # - context:      The service context that this entity belongs to
    # - namespaces:   Optional namespace to create the classes in
    def initialize(klass_name, methods, nav_props, context, namespace = nil)
      @klass_name = klass_name.camelcase
      @methods = methods
      @nav_props = nav_props
      @context = context
      @namespace = namespace
    end

    # Returns a dynamically generated class definition based on the constructor parameters
    def build
      # return if already built
      return @klass unless @klass.nil?

      # need the class name to build class
      return nil    if @klass_name.nil?

      # return if we can find constant corresponding to class name
      already_defined = eval("defined?(#{@klass_name}) == 'constant' and #{@klass_name}.class == Class")
      if already_defined
        @klass = @klass_name.constantize
        return @klass
      end

      if @namespace
        namespaces = @namespace.split(/\.|::/)

        namespaces.each_with_index do |ns, index|
          if index == 0
            next if Object.const_defined? ns
            Object.const_set(ns, Module.new)
          else
            current_ns = namespaces[0..index-1].join '::'
            next if eval "#{current_ns}.const_defined? '#{ns}'"
            eval "#{current_ns}.const_set('#{ns}', Module.new)"
          end
        end

        klass_constant = @klass_name.split('::').last
        eval "#{namespaces.join '::'}.const_set('#{klass_constant}', Class.new.extend(ActiveSupport::JSON))"
      else
        Object.const_set(@klass_name, Class.new.extend(ActiveSupport::JSON))
      end

      @klass = @klass_name.constantize
      @klass.class_eval do
        include OData
      end

      add_initializer(@klass)
      add_methods(@klass)
      add_nav_props(@klass)
      add_class_methods(@klass)

      return @klass
    end

    private
    def add_initializer(klass)
      klass.send :define_method, :initialize do |*args|
        return if args.blank?
        props = args[0]
        return unless props.is_a? Hash
        props.each do |k,v|
          raise NoMethodError, "undefined method `#{k}'" unless self.respond_to? k.to_sym
          instance_variable_set("@#{k}", v)
        end
      end
    end
    
    def add_methods(klass)
      # Add metadata methods
      klass.send :define_method, :__metadata do
        instance_variable_get("@__metadata")
      end
      klass.send :define_method, :__metadata= do |value|
        instance_variable_set("@__metadata", value)
      end
      klass.send :define_method, :as_json do |*args|
        meta = RUBY_VERSION < "1.9" ? '@__metadata' : ('@__metadata'.to_sym)

        options = args[0] || {}
        options[:type] ||= :unknown

        vars = self.instance_values

        if options[:type] == :add
          # For adds, we need to get rid of all attributes except __metadata when passing
          # the object to the server
          vars.each_value do |value|
            if value.is_a? OData
              child_vars = value.instance_variables
              if(child_vars.include?(meta))
                child_vars.each do |var|
                  value.send :remove_instance_variable, var if var != meta
                end
              else
                value.send :remove_instance_variable, meta if value.instance_variable_defined? meta
              end
            end
          end
        end

        # Convert a BigDecimal to a string for serialization (to match Edm.Decimal)
        decimals = vars.find_all { |o| o[1].class == BigDecimal } || []
        decimals.each do |d|
          vars[d[0]] = d[1].to_s
        end

        # Convert Time to an RFC3339 string for serialization
        times = vars.find_all { |o| o[1].class == Time } || []
        times.each do |t|
          sdate = t[1].xmlschema(3)
          # Remove the ending Z (indicating UTC).
          # If the Z is there when saving, the time is converted to local time on the server
          sdate.chop! if sdate.match(/Z$/)
          vars[t[0]] = sdate
        end

        if options[:type] == :link
          # For links, delete all of the vars and just add a uri
          uri = self.__metadata[:uri]
          vars = { 'uri' => uri }
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
      
      # Add an id method pulling out the id from the uri (mainly for Pickle support) if one doesn't already exist
      unless klass.send :respond_to?, :id
        klass.send :define_method, :id do
          metadata = self.__metadata
          id = nil
          if metadata && metadata[:uri]  =~ /\((\d+)\)$/
            id = $~[1]
          end
          return (true if Integer(id) rescue false) ? id.to_i : id
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

    def add_class_methods(klass)
      list_of_properties = @methods.concat @nav_props

      klass.send :define_singleton_method, 'properties' do
        list_of_properties
      end
    end
  end
end # module OData
