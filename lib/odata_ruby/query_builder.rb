module OData
# The query builder is used to call query operations against the service.  This shouldn't be called directly, but rather it is returned from the dynamic methods created for the specific service that you are calling.
#
# For example, given the following code snippet:
# 		svc = OData::Service.new "http://127.0.0.1:8888/SampleService/Entities.svc"
# 		svc.Categories
# The *Categories* method would return a QueryBuilder 
class QueryBuilder
	# Creates a new instance of the QueryBuilder class
	#
	# ==== Required Attributes
	# - root: The root entity collection to query against
	def initialize(root)
		@root = root.to_s
		@expands = []
		@filters = []
	end
	
	# Used to eagerly-load data for nested objects, for example, obtaining a Category for a Product within one call to the server
	# ==== Required Attributes
	# - path: The path of the entity to expand relative to the root
	#
	# ==== Example
	# 	# Without expanding the query (no Category will be filled in for the Product)
	# 	svc.Products(1)
	# 	prod1 = svc.execute
	#
	# 	# With expanding the query (the Category will be filled in)
	# 	svc.Products(1).expand('Category')
	# 	prod1 = svc.execute
	def expand(path)
		@expands << path
		self
	end
	
	# Used to filter data being returned
	# ==== Required Attributes
	# - filter: The path of the entity to expand relative to the root
	#
	# ==== Example	
	# 	svc.Products.filter("Name eq 'Product 2'")
	# 	prod = svc.execute
	def filter(filter)
		@filters << CGI.escape(filter)
		self
	end
	
	# Builds the query URI (path, not including root) incorporating expands, filters, etc.
	# This is used internally when the execute method is called on the service
	def query
		q = @root.clone
		query_options = []
		query_options << "$expand=#{@expands.join(',')}" unless @expands.empty?
		query_options << "$filter=#{@filters.join('+and+')}" unless @filters.empty?
		if !query_options.empty?
			q << "?"
			q << query_options.join('&')	
		end
		return q	
	end
end

end # Module