module OData
# The main service class, also known as a *Context*
class Service
  attr_reader :classes, :class_metadata, :options, :collections, :edmx, :function_imports
  # Creates a new instance of the Service class
  #
  # @param [String] service_uri the root URI of the OData service
  # @param [Hash] options the options to pass to the service
  # @option options [String] :username for http basic auth
  # @option options [String] :password for http basic auth
  # @option options [Object] :verify_ssl false if no verification, otherwise mode (OpenSSL::SSL::VERIFY_PEER is default)
  # @option options [Hash] :rest_options a hash of rest-client options that will be passed to all RestClient::Resource.new calls
  # @option options [Hash] :additional_params a hash of query string params that will be passed on all calls
  # @option options [Boolean, true] :eager_partial true if queries should consume partial feeds until the feed is complete, false if explicit calls to next must be performed
  def initialize(service_uri, options = {})
    @uri = service_uri.gsub!(/\/?$/, '')
    set_options! options
    default_instance_vars!
    set_namespaces
    build_collections_and_classes
  end

  # Handles the dynamic `AddTo<EntityName>` methods as well as the collections on the service
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
    elsif @function_imports.include?(name.to_s)
      execute_import_function(name.to_s, args)
    else
      super
    end
  end

  # Queues an object for deletion.  To actually remove it from the server, you must call save_changes as well.
  #
  # @param [Object] obj the object to mark for deletion
  #
  # @raise [NotSupportedError] if the `obj` isn't a tracked entity
  def delete_object(obj)
    type = obj.class.to_s
    if obj.respond_to?(:__metadata) && !obj.send(:__metadata).nil?
      @save_operations << Operation.new("Delete", type, obj)
    else
      raise OData::NotSupportedError.new "You cannot delete a non-tracked entity"
    end
  end

  # Queues an object for update.  To actually update it on the server, you must call save_changes as well.
  #
  # @param [Object] obj the object to queue for update
  #
  # @raise [NotSupportedError] if the `obj` isn't a tracked entity
  def update_object(obj)
    type = obj.class.to_s
    if obj.respond_to?(:__metadata) && !obj.send(:__metadata).nil?
      @save_operations << Operation.new("Update", type, obj)
    else
      raise OData::NotSupportedError.new "You cannot update a non-tracked entity"
    end
  end

  # Performs save operations (Create/Update/Delete) against the server
  def save_changes
    return nil if @save_operations.empty?

    result = nil

    begin
      if @save_operations.length == 1
        result = single_save(@save_operations[0])
      else
        result = batch_save(@save_operations)
      end

      # TODO: We should probably perform a check here
      # to make sure everything worked before clearing it out
      @save_operations.clear

      return result
    rescue Exception => e
      handle_exception(e)
    end
  end

  # Performs query operations (Read) against the server.
  # Typically this returns an array of record instances, except in the case of count queries
  def execute
    result = RestClient::Resource.new(build_query_uri, @rest_options).get
    return Integer(result) if result =~ /^\d+$/
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
    # Function Imports
    elsif @function_imports.include?(method.to_s)
      return true
    else
      super
    end
  end

  # Retrieves the next resultset of a partial result (if any). Does not honor the `:eager_partial` option.
  def next
    return if not partial?
    handle_partial
  end

  # Does the most recent collection returned represent a partial collection? Will aways be false if a query hasn't executed, even if the query would have a partial
  def partial?
    @has_partial
  end

  # Lazy loads a navigation property on a model
  #
  # @param [Object] obj the object to fill
  # @param [String] nav_prop the navigation property to fill
  #
  # @raise [NotSupportedError] if the `obj` isn't a tracked entity
  # @raise [ArgumentError] if the `nav_prop` isn't a valid navigation property
  def load_property(obj, nav_prop)
    raise NotSupportedError, "You cannot load a property on an entity that isn't tracked" if obj.send(:__metadata).nil?
    raise ArgumentError, "'#{nav_prop}' is not a valid navigation property" unless obj.respond_to?(nav_prop.to_sym)
    raise ArgumentError, "'#{nav_prop}' is not a valid navigation property" unless @class_metadata[obj.class.to_s][nav_prop].nav_prop
    results = RestClient::Resource.new(build_load_property_uri(obj, nav_prop), @rest_options).get
    prop_results = build_classes_from_result(results)
    obj.send "#{nav_prop}=", (singular?(nav_prop) ? prop_results.first : prop_results)
  end

  # Adds a child object to a parent object's collection
  #
  # @param [Object] parent the parent object
  # @param [String] nav_prop the name of the navigation property to add the child to
  # @param [Object] child the child object
  # @raise [NotSupportedError] if the `parent` isn't a tracked entity
  # @raise [ArgumentError] if the `nav_prop` isn't a valid navigation property
  # @raise [NotSupportedError] if the `child` isn't a tracked entity
  def add_link(parent, nav_prop, child)
    raise NotSupportedError, "You cannot add a link on an entity that isn't tracked (#{parent.class})" if parent.send(:__metadata).nil?
    raise ArgumentError, "'#{nav_prop}' is not a valid navigation property for #{parent.class}" unless parent.respond_to?(nav_prop.to_sym)
    raise ArgumentError, "'#{nav_prop}' is not a valid navigation property for #{parent.class}" unless @class_metadata[parent.class.to_s][nav_prop].nav_prop
    raise NotSupportedError, "You cannot add a link on a child entity that isn't tracked (#{child.class})" if child.send(:__metadata).nil?
    @save_operations << Operation.new("AddLink", nav_prop, parent, child)
  end

  private

  def set_options!(options)
    @options = options
    if @options[:eager_partial].nil?
      @options[:eager_partial] = true
    end
    @rest_options = { :verify_ssl => get_verify_mode, :user => @options[:username], :password => @options[:password] }
    @rest_options.merge!(options[:rest_options] || {})
    @additional_params = options[:additional_params] || {}
    @namespace = options[:namespace]
  end

  def default_instance_vars!
    @collections = {}
    @function_imports = {}
    @save_operations = []
    @has_partial = false
    @next_uri = nil
  end

  def set_namespaces
    @edmx = Nokogiri::XML(RestClient::Resource.new(build_metadata_uri, @rest_options).get)
    @ds_namespaces = {
      "m" => "http://schemas.microsoft.com/ado/2007/08/dataservices/metadata",
      "edmx" => "http://schemas.microsoft.com/ado/2007/06/edmx",
      "ds" => "http://schemas.microsoft.com/ado/2007/08/dataservices",
      "atom" => "http://www.w3.org/2005/Atom"
    }

    # Get the edm namespace from the edmx
    edm_ns = @edmx.xpath("edmx:Edmx/edmx:DataServices/*", @namespaces).first.namespaces['xmlns'].to_s
    @ds_namespaces.merge! "edm" => edm_ns
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

    # Build complex types first, these will be used for entities
    complex_types = @edmx.xpath("//edm:ComplexType", @ds_namespaces) || []
    complex_types.each do |c|
      name = qualify_class_name(c['Name'])
      props = c.xpath(".//edm:Property", @ds_namespaces)
      methods = props.collect { |p| p['Name'] } # Standard Properties
      @classes[name] = ClassBuilder.new(name, methods, [], self, @namespace).build unless @classes.keys.include?(name)
    end

    entity_types = @edmx.xpath("//edm:EntityType", @ds_namespaces)
    entity_types.each do |e|
      next if e['Abstract'] == "true"
      klass_name = qualify_class_name(e['Name'])
      methods = collect_properties(klass_name, e, @edmx)
      nav_props = collect_navigation_properties(klass_name, e, @edmx)
      @classes[klass_name] = ClassBuilder.new(klass_name, methods, nav_props, self, @namespace).build unless @classes.keys.include?(klass_name)
    end

    # Fill in the collections instance variable
    collections = @edmx.xpath("//edm:EntityContainer/edm:EntitySet", @ds_namespaces)
    collections.each do |c|
      entity_type = c["EntityType"]
      @collections[c["Name"]] = { :edmx_type => entity_type, :type => convert_to_local_type(entity_type) }
    end

    build_function_imports
  end

  # Parses the function imports and fills the @function_imports collection
  def build_function_imports
    # Fill in the function imports
    functions = @edmx.xpath("//edm:EntityContainer/edm:FunctionImport", @ds_namespaces)
    functions.each do |f|
      http_method = f.xpath("@m:HttpMethod", @ds_namespaces).first.content
      return_type = f["ReturnType"]
      inner_return_type = nil
      unless return_type.nil?
        return_type = (return_type =~ /^Collection/) ? Array : convert_to_local_type(return_type)
        if f["ReturnType"] =~ /\((.*)\)/
          inner_return_type = convert_to_local_type($~[1])
        end
      end
      params = f.xpath("edm:Parameter", @ds_namespaces)
      parameters = nil
      if params.length > 0
        parameters = {}
        params.each do |p|
          parameters[p["Name"]] = p["Type"]
        end
      end
      @function_imports[f["Name"]] = {
        :http_method => http_method,
        :return_type => return_type,
        :inner_return_type => inner_return_type,
        :parameters => parameters }
    end
  end

  # Converts the EDMX model type to the local model type
  def convert_to_local_type(edmx_type)
    return edm_to_ruby_type(edmx_type) if edmx_type =~ /^Edm/
    klass_name = qualify_class_name(edmx_type.split('.').last)
    klass_name.camelize.constantize
  end

  # Converts a class name to its fully qualified name (if applicable) and returns the new name
  def qualify_class_name(klass_name)
    unless @namespace.nil? || @namespace.blank? || klass_name.include?('::')
      namespaces = @namespace.split(/\.|::/)
      namespaces << klass_name
      klass_name = namespaces.join '::'
    end
    klass_name.camelize
  end

  # Builds the metadata need for each property for things like feed customizations and navigation properties
  def build_property_metadata(props)
    metadata = {}
    props.each do |property_element|
      prop_meta = PropertyMetadata.new(property_element)
      # If this is a navigation property, we need to add the association to the property metadata
      prop_meta.association = Association.new(property_element, @edmx) if prop_meta.nav_prop
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

  # Handles errors from the OData service
  def handle_exception(e)
    raise e unless e.response

    code = e.http_code
    error = Nokogiri::XML(e.response)

    message = error.xpath("m:error/m:message", @ds_namespaces).first.content
    raise "HTTP Error #{code}: #{message}"
  end

  # Loops through the standard properties (non-navigation) for a given class and returns the appropriate list of methods
  def collect_properties(klass_name, element, doc)
    props = element.xpath(".//edm:Property", @ds_namespaces)
    @class_metadata[klass_name] = build_property_metadata(props)
    methods = props.collect { |p| p['Name'] }
    unless element["BaseType"].nil?
      base = element["BaseType"].split(".").last()
      baseType = doc.xpath("//edm:EntityType[@Name=\"#{base}\"]", @ds_namespaces).first()
      props = baseType.xpath(".//edm:Property", @ds_namespaces)
      @class_metadata[klass_name].merge!(build_property_metadata(props))
      methods = methods.concat(props.collect { |p| p['Name']})
    end
    methods
  end

  # Similar to +collect_properties+, but handles the navigation properties
  def collect_navigation_properties(klass_name, element, doc)
    nav_props = element.xpath(".//edm:NavigationProperty", @ds_namespaces)
    @class_metadata[klass_name].merge!(build_property_metadata(nav_props))
    nav_props.collect { |p| p['Name'] }
  end

  # Helper to loop through a result and create an instance for each entity in the results
  def build_classes_from_result(result)
    doc = Nokogiri::XML(result)

    is_links = doc.at_xpath("/ds:links", @ds_namespaces)
    return parse_link_results(doc) if is_links

    entries = doc.xpath("//atom:entry[not(ancestor::atom:entry)]", @ds_namespaces)

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
    klass_name = entry.xpath("./atom:category/@term", @ds_namespaces).to_s.split('.')[-1]

    # Is the category missing? See if there is a title that we can use to build the class
    if klass_name.nil?
      title = entry.xpath("./atom:title", @ds_namespaces).first
      return nil if title.nil?
      klass_name = title.content.to_s
    end

    return nil if klass_name.nil?

    # If we are working against a child (inline) entry, we need to use the more generic xpath because a child entry WILL
    # have properties that are ancestors of m:inline. Check if there is an m:inline child to determine the xpath query to use
    has_inline = entry.xpath(".//m:inline", @ds_namespaces).any?
    properties_xpath = has_inline ? ".//m:properties[not(ancestor::m:inline)]/*" : ".//m:properties/*"
    properties = entry.xpath(properties_xpath, @ds_namespaces)

    klass = @classes[qualify_class_name(klass_name)].new

    # Fill metadata
    meta_id = entry.xpath("./atom:id", @ds_namespaces)[0].content
    klass.send :__metadata=, { :uri => meta_id }

    # Fill properties
    for prop in properties
      prop_name = prop.name
      klass.send "#{prop_name}=", parse_value(prop)
    end

    # Fill properties represented outside of the properties collection
    @class_metadata[qualify_class_name(klass_name)].select { |k,v| v.fc_keep_in_content == false }.each do |k, meta|
      if meta.fc_target_path == "SyndicationTitle"
        title = entry.xpath("./atom:title", @ds_namespaces).first
        klass.send "#{meta.name}=", title.content
      elsif meta.fc_target_path == "SyndicationSummary"
        summary = entry.xpath("./atom:summary", @ds_namespaces).first
        klass.send "#{meta.name}=", summary.content
      end
    end

    inline_links = entry.xpath("./atom:link[m:inline]", @ds_namespaces)

    for link in inline_links
      inline_entries = link.xpath(".//atom:entry", @ds_namespaces)

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
        property_name = link.xpath("@title", @ds_namespaces)
        klass.send "#{property_name}=", inline_classes
      end
    end

    klass
  end

  # Tests for and extracts the next href of a partial
  def extract_partial(doc)
    next_links = doc.xpath('//atom:link[@rel="next"]', @ds_namespaces)
    @has_partial = next_links.any?
    if @has_partial
      uri = Addressable::URI.parse(next_links[0]['href']) 
      uri.query_values = uri.query_values.merge @additional_params unless @additional_params.empty?
      @next_uri = uri.to_s
    end
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
    uris = doc.xpath("/ds:links/ds:uri", @ds_namespaces)
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
  def build_add_link_uri(operation)
    uri = operation.klass.send(:__metadata)[:uri].dup
    uri << "/$links/#{operation.klass_name}"
    uri << "?#{@additional_params.to_query}" unless @additional_params.empty?
    uri
  end
  def build_resource_uri(operation)
    uri = operation.klass.send(:__metadata)[:uri].dup
    uri << "?#{@additional_params.to_query}" unless @additional_params.empty?
    uri
  end
  def build_batch_uri
    uri = "#{@uri}/$batch"
    uri << "?#{@additional_params.to_query}" unless @additional_params.empty?
    uri
  end
  def build_load_property_uri(obj, property)
    uri = obj.__metadata[:uri].dup
    uri << "/#{property}"
    uri
  end
  def build_function_import_uri(name, params)
    uri = "#{@uri}/#{name}"
    params.merge! @additional_params
    uri << "?#{params.to_query}" unless params.empty?
    uri
  end

  def build_inline_class(klass, entry, property_name)
    # Build the class
    inline_klass = entry_to_class(entry)

    # Add the property
    klass.send "#{property_name}=", inline_klass
  end

  # Used to link a child object to its parent and vice-versa after a add_link operation
  def link_child_to_parent(operation)
    child_collection = operation.klass.send("#{operation.klass_name}") || []
    child_collection << operation.child_klass
    operation.klass.send("#{operation.klass_name}=", child_collection)

    # Attach the parent to the child
    parent_meta = @class_metadata[operation.klass.class.to_s][operation.klass_name]
    child_meta = @class_metadata[operation.child_klass.class.to_s]
    # Find the matching relationship on the child object
    child_properties = Helpers.normalize_to_hash(
        child_meta.select { |k, prop|
          prop.nav_prop &&
              prop.association.relationship == parent_meta.association.relationship })

    child_property_to_set = child_properties.keys.first # There should be only one match
    # TODO: Handle many to many scenarios where the child property is an enumerable
    operation.child_klass.send("#{child_property_to_set}=", operation.klass)
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
    elsif operation.kind == "AddLink"
      save_uri = build_add_link_uri(operation)
      json_klass = operation.child_klass.to_json(:type => :link)
      post_result = RestClient::Resource.new(save_uri, @rest_options).post json_klass, {:content_type => :json}

      # Attach the child to the parent
      link_child_to_parent(operation) if (post_result.code == 204)

      return(post_result.code == 204)
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
    elsif
      save_uri = build_add_link_uri(operation)
      json_klass = operation.child_klass.to_json(:type => :link)

      content << "POST #{save_uri} HTTP/1.1\n"
      content << accept_headers
      content << json_klass
      link_child_to_parent(operation)
    end

    return content
  end

  # Complex Types
  def complex_type_to_class(complex_type_xml)
    klass_name = qualify_class_name(Helpers.get_namespaced_attribute(complex_type_xml, 'type', 'm').split('.')[-1])
    klass = @classes[klass_name].new

    # Fill in the properties
    properties = complex_type_xml.xpath(".//*")
    properties.each do |prop|
      klass.send "#{prop.name}=", parse_value(prop)
    end

    return klass
  end

  # Field Converters

  # Handles parsing datetimes from a string
  def parse_date(sdate)
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

  # Parses a value into the proper type based on an xml property element
  def parse_value(property_xml)
    property_type = Helpers.get_namespaced_attribute(property_xml, 'type', 'm')
    property_null = Helpers.get_namespaced_attribute(property_xml, 'null', 'm')

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
    return parse_date(property_xml.content) if property_type.match(/Edm.DateTime/)

    # If we can't parse the value, just return the element's content
    property_xml.content
  end

  # Parses a value into the proper type based on a specified return type
  def parse_primative_type(value, return_type)
    return value.to_i if return_type == Fixnum
    return value.to_d if return_type == Float
    return parse_date(value.to_s) if return_type == Time
    return value.to_s
  end

  # Converts an edm type (string) to a ruby type
  def edm_to_ruby_type(edm_type)
    return String if edm_type =~ /Edm.String/
    return Fixnum if edm_type =~ /^Edm.Int/
    return Float if edm_type =~ /Edm.Decimal/
    return Time if edm_type =~ /Edm.DateTime/
    return String
  end

  # Method Missing Handlers

  # Executes an import function
  def execute_import_function(name, *args)
    func = @function_imports[name]

    # Check the args making sure that more weren't passed in than the function needs
    param_count = func[:parameters].nil? ? 0 : func[:parameters].count
    arg_count = args.nil? ? 0 : args[0].count
    if arg_count > param_count
      raise ArgumentError, "wrong number of arguments (#{arg_count} for #{param_count})"
    end

    # Convert the parameters to a hash
    params = {}
    func[:parameters].keys.each_with_index { |key, i| params[key] = args[0][i] } unless func[:parameters].nil?

    function_uri = build_function_import_uri(name, params)
    result = RestClient::Resource.new(function_uri, @rest_options).send(func[:http_method].downcase, {})

    # Is this a 204 (No content) result?
    return true if result.code == 204

    # No? Then we need to parse the results. There are 4 kinds...
    if func[:return_type] == Array
      # a collection of entites
      return build_classes_from_result(result) if @classes.include?(func[:inner_return_type].to_s)
      # a collection of native types
      elements = Nokogiri::XML(result).xpath("//ds:element", @ds_namespaces)
      results = []
      elements.each do |e|
        results << parse_primative_type(e.content, func[:inner_return_type])
      end
      return results
    end

    # a single entity
    if @classes.include?(func[:return_type].to_s)
      entry = Nokogiri::XML(result).xpath("atom:entry[not(ancestor::atom:entry)]", @ds_namespaces)
      return entry_to_class(entry)
    end

    # or a single native type
    unless func[:return_type].nil?
      e = Nokogiri::XML(result).xpath("/*").first
      return parse_primative_type(e.content, func[:return_type])
    end

    # Nothing could be parsed, so just return if we got a 200 or not
    return (result.code == 200)
  end

  # Helpers
  def singular?(value)
    value.singularize == value
  end
end

end # module OData
