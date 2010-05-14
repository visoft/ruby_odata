require 'open-uri'
require 'rest_client'
require 'nokogiri'
require 'active_support/inflector'

module OData
	
class Service
	attr_reader :classes
	
	def initialize(service_uri)		
		@uri = service_uri
		@collections = get_collections
		build_classes
	end
	
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
				@save_operation = Operation.new("Add", $1, args[0])
			else
				super
			end
		else
			super
		end

	end

	def delete_object(obj)
		type = obj.class.to_s
		# TODO: Throw an exception if this isn't a tracked entity
		@save_operation = Operation.new("Delete", type, obj)
	end
	def save_changes
		return nil if @save_operation.nil?

		result = nil

		if @save_operation.kind == "Add"
			save_uri = "#{@uri}/#{@save_operation.klass_name}"
			json_klass = @save_operation.klass.to_json
			post_result = RestClient.post save_uri, json_klass, :content_type => :json
			result = build_classes_from_result(post_result)
		elsif @save_operation.kind == "Update"
			return nil
		elsif @save_operation.kind == "Delete"
			delete_uri = "#{@uri}/#{@save_operation.klass_name.pluralize}(#{@save_operation.klass.send(:Id)})"
			delete_result = RestClient.delete delete_uri
			return (delete_result.code == 204) 
		end

		@save_operation = nil # Clear out the last operation
		return result
	end

	def execute
		result = RestClient.get build_query_uri
		build_classes_from_result(result)
	end
	
	def respond_to?(method)
		super unless @collections.include?(method.to_s)
		return true
	end
	
	def debug_query
		puts build_query_uri
	end
	
	private 
	def get_collections
		doc = Nokogiri::XML(open(@uri))
		collections = doc.xpath("//app:collection", "app" => "http://www.w3.org/2007/app")
		collections.collect { |c| c["href"] }
	end	
	def build_classes
		@classes = Hash.new
		doc = Nokogiri::XML(open("#{@uri}/$metadata"))

		# Get the edm namespace
		edm_ns = doc.xpath("edmx:Edmx/edmx:DataServices/*", "edmx" => "http://schemas.microsoft.com/ado/2007/06/edmx").first.namespaces['xmlns'].to_s

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
	def entry_to_class(entry)
		klass_name = entry.xpath("./atom:link[@rel='edit']/@title", "atom" => "http://www.w3.org/2005/Atom").to_s
		return nil if klass_name.empty?

		properties = entry.xpath("./atom:content//m:properties/*", { "m" => "http://schemas.microsoft.com/ado/2007/08/dataservices/metadata", "atom" => "http://www.w3.org/2005/Atom" })
			
		klass = @classes[klass_name].new
		for prop in properties
			prop_name = prop.name
			# puts "#{prop_name} - #{prop.content}"
			klass.send "#{prop_name}=", prop.content 
		end
		
		inline_links = entry.xpath("./atom:link[m:inline]", { "m" => "http://schemas.microsoft.com/ado/2007/08/dataservices/metadata", "atom" => "http://www.w3.org/2005/Atom" })
		
		for	link in inline_links
			inline_entries = link.xpath(".//atom:entry", "atom" => "http://www.w3.org/2005/Atom")
			
			if inline_entries.length == 1
				property_name = link.attributes['title'].to_s
				
				# Build the class
				inline_klass = entry_to_class(inline_entries[0])
				
				# Add the property
				klass.send "#{property_name}=", inline_klass
      else
        # TODO: Handle multiple children
				for inline_entry in inline_entries
					property_name = link.xpath("atom:link[@rel='edit']/@title", "atom" => "http://www.w3.org/2005/Atom")
					
					# Build the class
					inline_klass = entry_to_class(property_name, inline_entry)
					
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

end

end # module OData