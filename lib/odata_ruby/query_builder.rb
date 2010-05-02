require 'active_support/inflector'

module OData
	
class QueryBuilder
	def initialize(root)
		@root = root
		@expands = []
	end
	def expand(path)
		@expands << path
	end
	def klass_name
		name = @root.split('(')[0][1..-1]
		name.camelize.singularize
	end
	def query
		q = @root
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