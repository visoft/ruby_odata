require 'open-uri'
require 'nokogiri'
require 'active_support/inflector'

module OData
	
class Service
	attr_reader :classes
	
	def initialize(service_uri)		
		@uri = service_uri
		@collections = get_collections
		@query = []
		build_classes
	end
	
	def method_missing(name, *args)
		super unless @collections.include?(name.to_s) 
		
		@query.push("/#{name.to_s.camelize}")
		
		# @classes[name.to_s.camelize.singularize].new
	end
	
	def execute
		puts build_query_uri
		@query.clear
	end
	
	def respond_to?(method)
		super unless @collections.include?(method.to_s)
		return true
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
	def build_query_uri
		"#{@uri}#{@query.join}"
	end
end

end # module OData