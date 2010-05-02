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
		super unless @collections.include?(name.to_s) 
		root = "/#{name.to_s.camelize}"
		root << "(#{args.join(',')})" unless args.empty?
		@query = QueryBuilder.new(root)	
		
		# @query.push("/#{name.to_s.camelize}(#{args.join(',')})") 
	end
	
	def execute
		result = RestClient.get build_query_uri
		build_classes_from_result(@query.klass_name, result)
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
		collections.collect { |c| c["href"].underscore }
	end	
	def build_classes
		@classes = Hash.new
		doc = Nokogiri::XML(open("#{@uri}/$metadata"))
		entity_types = doc.xpath("//edm:EntityType", "edm" => "http://schemas.microsoft.com/ado/2008/09/edm")
		entity_types.each do |e|
			name = e['Name']
			props = e.xpath(".//edm:Property", "edm" => "http://schemas.microsoft.com/ado/2008/09/edm")			
			methods = props.collect { |p| p['Name'].underscore }
			@classes[name] = ClassBuilder.new(name, methods).build unless @classes.keys.include?(name)
		end
	end
	def build_classes_from_result(root_class_name, result)
		doc = Nokogiri::XML(result)
		entries = doc.xpath("//atom:entry", "atom" => "http://www.w3.org/2005/Atom")
		return entry_to_class(root_class_name, entries[0]) if entries.length == 1
		
		results = []
		entries.each do |entry|
			results << entry_to_class(root_class_name, entry)
		end
		return results
	end
	def entry_to_class(klass_name, entry)
		properties = entry.xpath(".//m:properties[1]/*", "m" => "http://schemas.microsoft.com/ado/2007/08/dataservices/metadata")
			
		klass = @classes[klass_name].new
		for prop in properties
			prop_name = prop.name.underscore
			# puts "#{prop_name} - #{prop.content}"
			klass.send "#{prop_name}=", prop.content 
		end
		
		return klass
	end
	def build_query_uri
		"#{@uri}#{@query.query}"
	end
end

end # module OData