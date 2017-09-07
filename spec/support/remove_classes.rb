#
# Removes the classes which were created by the odata_service
#
def remove_classes(service)
  return if service.nil?

  service.class_metadata.each_key do |klass|
    next unless (String === klass )

    namespaces = klass.split(/\.|::/)
    (0..namespaces.count).each do |index|
      index = namespaces.count-index-1
      name = namespaces[index]
      if index == 0
        Object.send(:remove_const,name) if Object.const_defined? name
      else
        current_ns = namespaces[0..index-1].join '::'
        if !current_ns.blank? and  Object.const_defined? current_ns
          if eval "#{current_ns}.const_defined? '#{name}'"
            eval "#{current_ns}.send(:remove_const, '#{name}')"
          end 
        end
      end
    end

    # Object.send(:remove_const, klass)    if (String === klass and Object.const_defined? klass)
  end
end
