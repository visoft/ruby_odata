require 'active_support/inflector'
require 'cgi'

module OData
	
class QueryBuilder
	def initialize(root)
		@root = root.to_s
		@expands = []
		@filters = []
	end
	
	def expand(path)
		@expands << path
	end
	
	def filter(filter)
		@filters << CGI.escape(filter)
	end
	
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