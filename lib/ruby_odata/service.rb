module OData
  
class Service
  attr_reader :classes, :class_metadata, :options
  # Creates a new instance of the Service class
  #
  # ==== Required Attributes
  # - service_uri: The root URI of the OData service
  # ==== Options in options hash
  # - username: username for http basic auth
  # - password: password for http basic auth
  # - verify_ssl: false if no verification, otherwise mode (OpenSSL::SSL::VERIFY_PEER is default)
  # - additional_params: a hash of query string params that will be passed on all calls
  # - eager_partial: true (default) if queries should consume partial feeds until the feed is complete, false if explicit calls to next must be performed
  def initialize(service_uri, options = {})
    @uri = service_uri.gsub!(/\/?$/, '')
    set_options! options
    default_instance_vars!
    build_collections_and_classes
  end
  
  # Handles the dynamic AddTo<EntityName> methods as well as the collections on the service
  def method_missing(name, *args)
    # Queries
    if @collections.include?(name.to_s)
      root = "/#{name.to_s}"
      root << "(#{args.join(',')})" unless args.empty?
      @query = QueryBuilder.new(root, @additional_params)
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

  # Performs query operations (Read) against the server, returns an array of record instances.
  def execute        
    result = RestClient::Resource.new(build_query_uri, @rest_options).get
    handle_collection_result(result)
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
  
  # Retrieves the next resultset of a partial result (if any). Does not honor the :eager_partial option.
  def next
    return if not partial?
    handle_partial
  end
  
  # Does the most recent collection returned represent a partial collection? Will aways be false if a query hasn't executed, even if the query would have a partial
  def partial?
    @has_partial
  end

  
  private

  def set_options!(options)
    @options = options
    if @options[:eager_partial].nil?
      @options[:eager_partial] = true
    end
    @rest_options = { :verify_ssl => get_verify_mode, :user => @options[:username], :password => @options[:password] }
    @additional_params = options[:additional_params] || {}
  end
  
  def default_instance_vars!
    @collections = []
    @save_operations = []
    @has_partial = false
    @next_uri = nil
  end

  # Gets ssl certificate verification mode, or defaults to verify_peer
  def get_verify_mode
    if @options[:verify_ssl].nil?
      return OpenSSL::SSL::VERIFY_PEER
    else
      return @options[:verify_ssl]
    end
  end

  # Build the classes required by the metadata
  def build_collections_and_classes
    @classes = Hash.new
    @class_metadata = Hash.new # This is used to store property information about a class
    
    doc = Nokogiri::XML(RestClient::Resource.new(build_metadata_uri, @rest_options).get)
    
    # Get the edm namespace
    edm_ns = doc.xpath("edmx:Edmx/edmx:DataServices/*", "edmx" => "http://schemas.microsoft.com/ado/2007/06/edmx").first.namespaces['xmlns'].to_s

    # Fill in the collections instance variable
    collections = doc.xpath("//edm:EntityContainer/edm:EntitySet", "edm" => edm_ns)
    @collections = collections.collect { |c| c["Name"] }

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
      next if e['Abstract'] == "true"
      klass_name = e['Name']
      methods = collect_properties(klass_name,edm_ns, e, doc)
      nprops =  e.xpath(".//edm:NavigationProperty", "edm" => edm_ns)			
      nav_props = nprops.collect { |p| p['Name'] } # Navigation Properties
      @classes[klass_name] = ClassBuilder.new(klass_name, methods, nav_props).build unless @classes.keys.include?(klass_name)
    end
  end
  
  def build_property_metadata(props)
    metadata = {}
    props.each do |property_element|
      prop_meta = PropertyMetadata.new(property_element)
      metadata[prop_meta.name] = prop_meta
    end
    metadata
  end
  
  # Handle parsing of OData Atom result and return an array of Entry classes
  def handle_collection_result(result)
    results = build_classes_from_result(result)
    while partial? && @options[:eager_partial]
      results.concat handle_partial
    end
    results
  end
  

  def collect_properties(klass_name, edm_ns, element, doc)
    props = element.xpath(".//edm:Property", "edm" => edm_ns)
    @class_metadata[klass_name] = build_property_metadata(props)
    methods = props.collect { |p| p['Name'] }
    unless element["BaseType"].nil?
      base = element["BaseType"].split(".").last()
      baseType = doc.xpath("//edm:EntityType[@Name=\"#{base}\"]",
                           "edm" => edm_ns).first()
      props = baseType.xpath(".//edm:Property", "edm" => edm_ns)
      @class_metadata[klass_name].merge!(build_property_metadata(props))
      methods = methods.concat(props.collect { |p| p['Name']})
    end
    methods
  end

  # Helper to loop through a result and create an instance for each entity in the results
  def build_classes_from_result(result)
    doc = Nokogiri::XML(result)
    
    is_links = doc.at_xpath("/ds:links", "ds" => "http://schemas.microsoft.com/ado/2007/08/dataservices")
    return parse_link_results(doc) if is_links
    
    entries = doc.xpath("//atom:entry[not(ancestor::atom:entry)]", "atom" => "http://www.w3.org/2005/Atom")
    
    extract_partial(doc)
    
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
    
    # Is the category missing? See if there is a title that we can use to build the class
    if klass_name.nil?
      title = entry.xpath("./atom:title", "atom" => "http://www.w3.org/2005/Atom").first
      return nil if title.nil?
      klass_name = title.content.to_s
    end
        
    return nil if klass_name.nil?

    # If we are working against a child (inline) entry, we need to use the more generic xpath because a child entry WILL 
    # have properties that are ancestors of m:inline. Check if there is an m:inline child to determine the xpath query to use
    has_inline = entry.xpath(".//m:inline", { "m" => "http://schemas.microsoft.com/ado/2007/08/dataservices/metadata" }).any?
    properties_xpath = has_inline ? ".//m:properties[not(ancestor::m:inline)]/*" : ".//m:properties/*"
    properties = entry.xpath(properties_xpath, { "m" => "http://schemas.microsoft.com/ado/2007/08/dataservices/metadata" })

    klass = @classes[klass_name].new
    
    # Fill metadata
    meta_id = entry.xpath("./atom:id", "atom" => "http://www.w3.org/2005/Atom")[0].content
    klass.send :__metadata=, { :uri => meta_id }

    # Fill properties
    for prop in properties
      prop_name = prop.name
      klass.send "#{prop_name}=", parse_value(prop)
    end
    
    # Fill properties represented outside of the properties collection
    @class_metadata[klass_name].select { |k,v| v.fc_keep_in_content == false }.each do |k, meta|
      if meta.fc_target_path == "SyndicationTitle"
        title = entry.xpath("./atom:title", "atom" => "http://www.w3.org/2005/Atom").first
        klass.send "#{meta.name}=", title.content
      elsif meta.fc_target_path == "SyndicationSummary"
        summary = entry.xpath("./atom:summary", "atom" => "http://www.w3.org/2005/Atom").first
        klass.send "#{meta.name}=", summary.content
      end
    end
    
    inline_links = entry.xpath("./atom:link[m:inline]", { "m" => "http://schemas.microsoft.com/ado/2007/08/dataservices/metadata", "atom" => "http://www.w3.org/2005/Atom" })
    
    for	link in inline_links
      inline_entries = link.xpath(".//atom:entry", "atom" => "http://www.w3.org/2005/Atom")

      # TODO: Use the metadata's associations to determine the multiplicity instead of this "hack"  
      property_name = link.attributes['title'].to_s
      if inline_entries.length == 1 && singular?(property_name)
        inline_klass = build_inline_class(klass, inline_entries[0], property_name)
        klass.send "#{property_name}=", inline_klass
      else
        inline_classes = []
        for inline_entry in inline_entries
          # Build the class
          inline_klass = entry_to_class(inline_entry)

          # Add the property to the temp collection
          inline_classes << inline_klass
        end

        # Assign the array of classes to the property
        property_name = link.xpath("@title", "atom" => "http://www.w3.org/2005/Atom")
        klass.send "#{property_name}=", inline_classes
      end
    end
    
    klass
  end
  
  # Tests for and extracts the next href of a partial
  def extract_partial(doc)
    next_links = doc.xpath('//atom:link[@rel="next"]', "atom" => "http://www.w3.org/2005/Atom")
    @has_partial = next_links.any?
    @next_uri = next_links[0]['href'] if @has_partial
  end
  
  def handle_partial
    if @next_uri
      result = RestClient::Resource.new(@next_uri, @rest_options).get
      results = handle_collection_result(result)
    end
    results
  end
  
  # Handle link results
  def parse_link_results(doc)
    uris = doc.xpath("/ds:links/ds:uri", "ds" => "http://schemas.microsoft.com/ado/2007/08/dataservices")
    results = []
    uris.each do |uri_el|
      link = uri_el.content
      results << URI.parse(link)
    end
    results
  end   

  # Build URIs
  def build_metadata_uri
    uri = "#{@uri}/$metadata"
    uri << "?#{@additional_params.to_query}" unless @additional_params.empty?
    uri
  end
  def build_query_uri
    "#{@uri}#{@query.query}"
  end
  def build_save_uri(operation)
    uri = "#{@uri}/#{operation.klass_name}"
    uri << "?#{@additional_params.to_query}" unless @additional_params.empty?
    uri
  end
  def build_resource_uri(operation)
    uri = operation.klass.send(:__metadata)[:uri]
    uri << "?#{@additional_params.to_query}" unless @additional_params.empty?
    uri
  end
  def build_batch_uri
    uri = "#{@uri}/$batch"
    uri << "?#{@additional_params.to_query}" unless @additional_params.empty?
    uri    
  end
  
  def build_inline_class(klass, entry, property_name)
    # Build the class
    inline_klass = entry_to_class(entry)
  
    # Add the property
    klass.send "#{property_name}=", inline_klass
  end
  def single_save(operation)
    if operation.kind == "Add"
      save_uri = build_save_uri(operation)
      json_klass = operation.klass.to_json(:type => :add)
      post_result = RestClient::Resource.new(save_uri, @rest_options).post json_klass, {:content_type => :json}
      return build_classes_from_result(post_result)
    elsif operation.kind == "Update"
      update_uri = build_resource_uri(operation)
      json_klass = operation.klass.to_json
      update_result = RestClient::Resource.new(update_uri, @rest_options).put json_klass, {:content_type => :json}
      return (update_result.code == 204)
    elsif operation.kind == "Delete"
      delete_uri = build_resource_uri(operation)
      delete_result = RestClient::Resource.new(delete_uri, @rest_options).delete
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
    batch_uri = build_batch_uri
    
    body = build_batch_body(operations, batch_num, changeset_num)
    result = RestClient::Resource.new( batch_uri, @rest_options).post body, {:content_type => "multipart/mixed; boundary=batch_#{batch_num}"}

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
    property_null = property_xml.attr('null')

    # Handle a nil property type, this is a string
    return property_xml.content if property_type.nil?

    # Handle anything marked as null
    return nil if !property_null.nil? && property_null == "true"

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
      
      # This is to handle older versions of Ruby (e.g. ruby 1.8.7 (2010-12-23 patchlevel 330) [i386-mingw32])
      # See http://makandra.com/notes/1017-maximum-representable-value-for-a-ruby-time-object
      # In recent versions of Ruby, Time has a much larger range
      begin
        result = Time.parse(sdate)  
      rescue ArgumentError
        result = DateTime.parse(sdate)
      end
      
      return result
    end

    # If we can't parse the value, just return the element's content
    property_xml.content
  end

  # Helpers
  def singular?(value)
    value.singularize == value
  end
end

end # module OData