require 'logger'

module OData
  
class Service
  attr_reader :classes
  # Creates a new instance of the Service class
  #
  # ==== Required Attributes
  # - service_uri: The root URI of the OData service
  def initialize(service_uri)		
    @uri = service_uri
    @collections = get_collections
    @save_operations = []
    build_classes
  end
  
  # Handles the dynamic AddTo<EntityName> methods as well as the collections on the service
  def method_missing(name, *args)
    # Queries
    if @collections.include?(name.to_s)
      root = "/#{name.to_s.camelize}"
      root << "(#{args.join(',')})" unless args.empty?
      @query = QueryBuilder.new(root)
      return @query
    # Adds	
    elsif name.to_s =~ /^AddTo(.*)/
      type = $1
      if @collections.include?(type)
        @save_operations << Operation.new("Add", $1, args[0])
      else
        super
      end
    else
      super
    end

  end

  # Queues an object for deletion.  To actually remove it from the server, you must call save_changes as well.
  #
  # ==== Required Attributes
  # - obj: The object to mark for deletion
  #
  # Note: This method will throw an exception if the +obj+ isn't a tracked entity
  def delete_object(obj)
    type = obj.class.to_s
    if obj.respond_to?(:__metadata) && !obj.send(:__metadata).nil? 
      @save_operations << Operation.new("Delete", type, obj)
    else
      raise "You cannot delete a non-tracked entity"
    end
  end
  
  # Queues an object for update.  To actually update it on the server, you must call save_changes as well.
  # 
  # ==== Required Attributes
  # - obj: The object to queue for update
  #
  # Note: This method will throw an exception if the +obj+ isn't a tracked entity	
  def update_object(obj)
    type = obj.class.to_s
    if obj.respond_to?(:__metadata) && !obj.send(:__metadata).nil? 
      @save_operations << Operation.new("Update", type, obj)
    else
      raise "You cannot update a non-tracked entity"
    end		
  end
  
  # Performs save operations (Create/Update/Delete) against the server
  def save_changes
    return nil if @save_operations.empty?

    result = nil
    
    if @save_operations.length == 1
      result = single_save(@save_operations[0])			
    else	
      result = batch_save(@save_operations)			
    end
    
    # TODO: We should probably perform a check here 
    # to make sure everything worked before clearing it out
    @save_operations.clear 
    
    return result
  end

  # Performs query operations (Read) against the server
  def execute
    result = RestClient.get build_query_uri
    build_classes_from_result(result)
  end
  
  # Overridden to identify methods handled by method_missing  
  def respond_to?(method)
    if @collections.include?(method.to_s)
      return true
    # Adds	
    elsif method.to_s =~ /^AddTo(.*)/
      type = $1
      if @collections.include?(type)
        return true
      else
        super
      end
    else
      super
    end
  end
  
  private
  # Retrieves collections from the main service page
  def get_collections
    doc = Nokogiri::XML(open(@uri))
    collections = doc.xpath("//app:collection", "app" => "http://www.w3.org/2007/app")
    collections.collect { |c| c["href"] }
  end

  # Build the classes required by the metadata
  def build_classes
    @classes = Hash.new
    doc = Nokogiri::XML(open("#{@uri}/$metadata"))

    # Get the edm namespace
    edm_ns = doc.xpath("edmx:Edmx/edmx:DataServices/*", "edmx" => "http://schemas.microsoft.com/ado/2007/06/edmx").first.namespaces['xmlns'].to_s

    # Build complex types first, these will be used for entities
    complex_types = doc.xpath("//edm:ComplexType", "edm" => edm_ns) || []
    complex_types.each do |c|
      name = c['Name']
      props = c.xpath(".//edm:Property", "edm" => edm_ns)
      methods = props.collect { |p| p['Name'] } # Standard Properties
      @classes[name] = ClassBuilder.new(name, methods, []).build unless @classes.keys.include?(name)
    end

    entity_types = doc.xpath("//edm:EntityType", "edm" => edm_ns)
    entity_types.each do |e|
      name = e['Name']
      props = e.xpath(".//edm:Property", "edm" => edm_ns)
      methods = props.collect { |p| p['Name'] } # Standard Properties
      nprops =  e.xpath(".//edm:NavigationProperty", "edm" => edm_ns)			
      nav_props = nprops.collect { |p| p['Name'] } # Standard Properties
      @classes[name] = ClassBuilder.new(name, methods, nav_props).build unless @classes.keys.include?(name)
    end
  end

  # Helper to loop through a result and create an instance for each entity in the results
  def build_classes_from_result(result)
    doc = Nokogiri::XML(result)
    entries = doc.xpath("//atom:entry[not(ancestor::atom:entry)]", "atom" => "http://www.w3.org/2005/Atom")
    return entry_to_class(entries[0]) if entries.length == 1
    
    results = []
    entries.each do |entry|
      results << entry_to_class(entry)
    end
    return results
  end

  # Converts an XML Entry into a class
  def entry_to_class(entry)
    # Retrieve the class name from the fully qualified name (the last string after the last dot)
    klass_name = entry.xpath("./atom:category/@term", "atom" => "http://www.w3.org/2005/Atom").to_s.split('.')[-1]
    return nil if klass_name.empty?

    properties = entry.xpath(".//m:properties/*", { "m" => "http://schemas.microsoft.com/ado/2007/08/dataservices/metadata" })
        
    klass = @classes[klass_name].new
    
    # Fill metadata
    meta_id = entry.xpath("./atom:id", "atom" => "http://www.w3.org/2005/Atom")[0].content
    klass.send :__metadata=, { :uri => meta_id }

    # Fill properties
    for prop in properties
      prop_name = prop.name
      klass.send "#{prop_name}=", parse_value(prop)
    end
    
    inline_links = entry.xpath("./atom:link[m:inline]", { "m" => "http://schemas.microsoft.com/ado/2007/08/dataservices/metadata", "atom" => "http://www.w3.org/2005/Atom" })
    
    for	link in inline_links
      inline_entries = link.xpath(".//atom:entry", "atom" => "http://www.w3.org/2005/Atom")
      
      if inline_entries.length == 1
        property_name = link.attributes['title'].to_s
        
        build_inline_class(klass, inline_entries[0], property_name)
      else
        # TODO: Test handling multiple children
        for inline_entry in inline_entries
          property_name = link.xpath("atom:link[@rel='edit']/@title", "atom" => "http://www.w3.org/2005/Atom")
          
          # Build the class
          inline_klass = entry_to_class(inline_entry)
          
          # Add the property
          klass.send "#{property_name}=", inline_klass
        end
      end
    end
    
    return klass
  end

  def build_query_uri
    "#{@uri}#{@query.query}"
  end
  def build_inline_class(klass, entry, property_name)
    # Build the class
    inline_klass = entry_to_class(entry)
  
    # Add the property
    klass.send "#{property_name}=", inline_klass
  end
  def single_save(operation)
    if operation.kind == "Add"
      save_uri = "#{@uri}/#{operation.klass_name}"
      json_klass = operation.klass.to_json(:type => :add)
      post_result = RestClient.post save_uri, json_klass, :content_type => :json
      return build_classes_from_result(post_result)
    elsif operation.kind == "Update"
      update_uri = operation.klass.send(:__metadata)[:uri]
      json_klass = operation.klass.to_json
      update_result = RestClient.put update_uri, json_klass, :content_type => :json
      return (update_result.code == 204)
    elsif operation.kind == "Delete"
      delete_uri = operation.klass.send(:__metadata)[:uri]
      delete_result = RestClient.delete delete_uri
      return (delete_result.code == 204) 
    end		
  end

  # Batch Saves
  def generate_guid
    rand(36**12).to_s(36).insert(4, "-").insert(9, "-")
  end
  def batch_save(operations)	
    batch_num = generate_guid
    changeset_num = generate_guid
    batch_uri = "#{@uri}/$batch"
    
    body = build_batch_body(operations, batch_num, changeset_num)
    
    result = RestClient.post batch_uri, body, :content_type => "multipart/mixed; boundary=batch_#{batch_num}"
    
    # TODO: More result validation needs to be done.  
    # The result returns HTTP 202 even if there is an error in the batch
    return (result.code == 202)
  end
  def build_batch_body(operations, batch_num, changeset_num)
    # Header		
    body = "--batch_#{batch_num}\n"
    body << "Content-Type: multipart/mixed;boundary=changeset_#{changeset_num}\n\n"

    # Operations
    operations.each do |operation|
      body << build_batch_operation(operation, changeset_num)
      body << "\n"
    end
        
    # Footer		
    body << "\n\n--changeset_#{changeset_num}--\n"
    body << "--batch_#{batch_num}--"
    
    return body
  end
  def build_batch_operation(operation, changeset_num)
    accept_headers = "Accept-Charset: utf-8\n"
    accept_headers << "Content-Type: application/json;charset=utf-8\n" unless operation.kind == "Delete"
    accept_headers << "\n"
  
    content = "--changeset_#{changeset_num}\n"
    content << "Content-Type: application/http\n"
    content << "Content-Transfer-Encoding: binary\n\n"
    
    if operation.kind == "Add"			
      save_uri = "#{@uri}/#{operation.klass_name}"
      json_klass = operation.klass.to_json(:type => :add)
      
      content << "POST #{save_uri} HTTP/1.1\n"
      content << accept_headers
      content << json_klass
    elsif operation.kind == "Update"
      update_uri = operation.klass.send(:__metadata)[:uri]
      json_klass = operation.klass.to_json
      
      content << "PUT #{update_uri} HTTP/1.1\n"
      content << accept_headers
      content << json_klass
    elsif operation.kind == "Delete"
      delete_uri = operation.klass.send(:__metadata)[:uri]
      
      content << "DELETE #{delete_uri} HTTP/1.1\n"
      content << accept_headers
    end		
      
    return content
  end

  # Complex Types
  def complex_type_to_class(complex_type_xml)
    klass_name = complex_type_xml.attr('type').split('.')[-1]
    klass = @classes[klass_name].new

    # Fill in the properties
    properties = complex_type_xml.xpath(".//*")
    properties.each do |prop|
      klass.send "#{prop.name}=", parse_value(prop)
    end

    return klass
  end

  # Field Converters
  def parse_value(property_xml)
    property_type = property_xml.attr('type')

    # Handle a nil property type, this is a string
    return property_xml.content if property_type.nil?

    # Handle complex types
    return complex_type_to_class(property_xml) if !property_type.match(/^Edm/)

    # Handle integers
    return property_xml.content.to_i if property_type.match(/^Edm.Int/)

    # Handle decimals
    return property_xml.content.to_d if property_type.match(/Edm.Decimal/)

    # Handle DateTimes
    # return Time.parse(property_xml.content) if property_type.match(/Edm.DateTime/)
    if property_type.match(/Edm.DateTime/)
      sdate = property_xml.content

      # Assume this is UTC if no timezone is specified
      sdate = sdate + "Z" unless sdate.match(/Z|([+|-]\d{2}:\d{2})$/)

      return Time.parse(sdate)
    end

    # If we can't parse the value, just return the element's content
    property_xml.content
  end

end

end # module OData