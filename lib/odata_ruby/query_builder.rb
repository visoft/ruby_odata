require 'active_support/inflector'

module OData
	
class QueryBuilder
	def initialize(root)
		@root = root.to_s
		@expands = []
	end
	def expand(path)
		@expands << path
	end
	def query
		q = @root.clone
		query_options = []
		query_options << "$expand=#{@expands.join(',')}" unless @expands.empty?
		if !query_options.empty?
			q << "?"
			q << query_options.join('&')	
		end
		
		return q	
	end
end

end # Module