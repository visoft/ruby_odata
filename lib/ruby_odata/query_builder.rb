module OData
  # The query builder is used to call query operations against the service.  This shouldn't be called directly, but rather it is returned from the dynamic methods created for the specific service that you are calling.
  #
  # @example For example, given the following code snippet:
  #   svc = OData::Service.new "http://127.0.0.1:8989/SampleService/RubyOData.svc"
  #   svc.Categories
  # The *Categories* method would return a QueryBuilder
  class QueryBuilder
    attr_accessor :additional_params

    # Creates a new instance of the QueryBuilder class
    #
    # @param [String] root entity collection to query against
    # @param [Hash, {}] additional_params hash of additional parameters to use for a query
    def initialize(root, additional_params = {})
      @root = Helpers.uri_escape(root.to_s)
      @expands = []
      @filters = []
      @order_bys = []
      @navigation_paths = []
      @select = []
      @skip = nil
      @top = nil
      @count = nil
      @links_navigation_property = nil
      @additional_params = additional_params
    end

    # Used to eagerly-load data for nested objects, for example, obtaining a Category for a Product within one call to the server
    #
    # @param [String] path of the entity to expand relative to the root
    # @example
    #   # Without expanding the query (no Category will be filled in for the Product)
    #   svc.Products(1)
    #   prod1 = svc.execute
    #
    #   # With expanding the query (the Category will be filled in)
    #   svc.Products(1).expand('Category')
    #   prod1 = svc.execute
    def expand(path)
      @expands << path
      self
    end

    # Used to filter data being returned
    #
    # @param [String] filter conditions to apply to the query
    #
    # @example
    #  svc.Products.filter("Name eq 'Product 2'")
    #  products = svc.execute
    def filter(filter)
      @filters << CGI.escape(filter)
      self
    end

    # Used to order the data being returned
    #
    # @param [String] order_by the order by statement.  Note to specify direction, use "desc" or "asc"; must be lowercase
    #
    # @example
    #   svc.Products.order_by("Name")
    #   products = svc.execute
    def order_by(order_by)
      @order_bys << CGI.escape(order_by)
      self
    end

    # Used to skip a number of records
    # This is typically used for paging, where it would be used along with the `top` method.
    #
    # @param [Integer] num the number of items to skip
    #
    # @example
    #   svc.Products.skip(5)
    #   products = svc.execute # => skips the first 5 items
    def skip(num)
      @skip = num
      self
    end

    # Used to take only the top X records
    # This is typically used for paging, where it would be used along with the `skip` method.
    #
    # @param [Integer] num the number of items to return
    #
    # @example
    #   svc.Products.top(5)
    #   products = svc.execute # => returns only the first 5 items
    def top(num)
      @top = num
      self
    end

    # Used to return links instead of actual objects
    #
    # @param [String] navigation_property the NavigationProperty name to retrieve the links for
    #
    # @raise [NotSupportedError] if count has already been called on the query
    #
    # @example
    #   svc.Categories(1).links("Products")
    #   product_links = svc.execute # => returns URIs for the products under the Category with an ID of 1
    def links(navigation_property)
      raise OData::NotSupportedError.new("You cannot call both the `links` method and the `count` method in the same query.") if @count
      raise OData::NotSupportedError.new("You cannot call both the `links` method and the `select` method in the same query.") unless @select.empty?
      @links_navigation_property = navigation_property
      self
    end

    # Used to return a count of objects instead of the objects themselves
    #
    # @raise [NotSupportedError] if links has already been called on the query
    #
    # @example
    #   svc.Products
    #   svc.count
    #   product_count = svc.execute
    def count
      raise OData::NotSupportedError.new("You cannot call both the `links` method and the `count` method in the same query.") if @links_navigation_property
      raise OData::NotSupportedError.new("You cannot call both the `select` method and the `count` method in the same query.") unless @select.empty?

      @count = true
      self
    end

    # Used to navigate to a child collection, typically used to filter or perform a similar function against the children
    #
    # @param [String] navigation_property the NavigationProperty to drill-down into
    #
    # @example
    #   svc.Genres('Horror Movies').navigate("Titles").filter("Name eq 'Halloween'")
    def navigate(navigation_property)
      @navigation_paths << Helpers.uri_escape(navigation_property)
      self
    end

    # Used to customize the properties that are returned for "ad-hoc" queries
    #
    # @param [Array<String>] properties to return
    #
    # @example
    #   svc.Products.select('Price', 'Rating')
    def select(*fields)
      raise OData::NotSupportedError.new("You cannot call both the `links` method and the `select` method in the same query.") if @links_navigation_property
      raise OData::NotSupportedError.new("You cannot call both the `count` method and the `select` method in the same query.") if @count

      @select |= fields

      expands =  fields.find_all { |f| /\// =~ f }
      expands.each do |e|
        parts = e.split '/'
        @expands |= [parts[0...-1].join('/')]
      end

      self
    end

    # Builds the query URI (path, not including root) incorporating expands, filters, etc.
    # This is used internally when the execute method is called on the service
    def query
      q = @root.clone

      # Navigation paths come first in the query
      q << "/#{@navigation_paths.join("/")}" unless @navigation_paths.empty?

      # Handle links queries, this isn't just a standard query option
      q << "/$links/#{@links_navigation_property}" if @links_navigation_property

      # Handle count queries, this isn't just a standard query option
      q << "/$count" if @count
      query_options = generate_query_options

      q << "?#{query_options.join('&')}" if !query_options.empty?
      q
    end

    private

    def generate_query_options
      query_options = []
      query_options << "$select=#{@select.join(',')}" unless @select.empty?
      query_options << "$expand=#{@expands.join(',')}" unless @expands.empty?
      query_options << "$filter=#{@filters.join('+and+')}" unless @filters.empty?
      query_options << "$orderby=#{@order_bys.join(',')}" unless @order_bys.empty?
      query_options << "$skip=#{@skip}" unless @skip.nil?
      query_options << "$top=#{@top}" unless @top.nil?
      query_options << @additional_params.to_query unless @additional_params.empty?
      query_options
    end
  end
end # Module