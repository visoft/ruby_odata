module OData
  # Internally used helper class for storing an entity property's metadata.  This class shouldn't be used directly.
  class PropertyMetadata
    # The property name
    attr_reader :name
    # The property EDM type
    attr_reader :type
    # Is the property nullable?
    attr_reader :nullable
    # Feed customization target path
    attr_reader :fc_target_path
    # Should the property appear in both the mapped schema path and the properties collection
    attr_reader :fc_keep_in_content
    # Is the property a navigation property?
    attr_reader :nav_prop
    # Applies only to navigation properties; the association corresponding to the property
    attr_accessor :association
    # Applies to the primary key(s)
    attr_accessor :is_key

    # Creates a new instance of the Class Property class
    #
    # @param [Nokogiri::XML::Node] property_element from the EDMX

    def initialize(property_element)
      @name =                 property_element['Name']
      @type =                 property_element['Type']
      @nullable =             ((property_element['Nullable'] && property_element['Nullable'] == "true") || property_element.name == 'NavigationProperty') || false
      @fc_target_path =       Helpers.get_namespaced_attribute(property_element, 'FC_TargetPath', 'm')
      keep_in_content =       Helpers.get_namespaced_attribute(property_element, 'FC_KeepInContent', 'm')
      @fc_keep_in_content  =  (keep_in_content) ? (keep_in_content == "true") : nil
      @nav_prop =             property_element.name == 'NavigationProperty'
    end
  end
end