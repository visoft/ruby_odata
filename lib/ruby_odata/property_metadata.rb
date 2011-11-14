module OData
  # Internally used helper class for storing an entity property's metadata.  This class shouldn't be used directly.
  class PropertyMetadata
    # The property name
    attr_accessor :name
    # The property EDM type
    attr_accessor :type
    # Is the property nullable?
    attr_accessor :nullable
    # Feed customization target path
    attr_accessor :fc_target_path
    # Should the property appear in both the mapped schema path and the properties collection
    attr_accessor :fc_keep_in_content
    # Is the property a navigation property?
    attr_accessor :nav_prop
    
    # Creates a new instance of the Class Property class
    #
    # ==== Required Attributes
    # property_element: The property element from the EDMX 
    
    def initialize(property_element)      
      @name =                 property_element['Name']
      @type =                 property_element['Type']
      @nullable =             (property_element['Nullable'] && property_element['Nullable'] == "true") || false
      @fc_target_path =       property_element['FC_TargetPath']
      @fc_keep_in_content  =  (property_element['FC_KeepInContent']) ? (property_element['FC_KeepInContent'] == "true") : nil
      @nav_prop =             property_element.name == 'NavigationProperty'
    end
  end
end