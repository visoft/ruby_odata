module OData
  class Resource
    attr_reader :url, :options, :block

    def initialize(url, options={}, backwards_compatibility=nil, &block)
      @url = url
      @block = block
      @options = options.is_a?(Hash) ? options : { user: options, password: backwards_compatibility }

      @conn = Faraday.new(url: url, ssl: { verify: verify_ssl }) do |faraday|
        faraday.use      :gzip
        faraday.response :raise_error
        faraday.adapter  :excon

        faraday.options.timeout      = timeout if timeout
        faraday.options.open_timeout = open_timeout if open_timeout

        faraday.headers = (faraday.headers || {}).merge(@options[:headers] || {})
        faraday.headers = (faraday.headers).merge({
          :accept => '*/*; q=0.5, application/xml',
        })

        faraday.basic_auth user, password if user# this adds to headers so must be behind
      end

      @conn.headers[:user_agent] = 'Ruby'
    end

    def get(additional_headers={})
      @conn.get do |req|
        req.url url
        req.headers = (headers || {}).merge(additional_headers)
      end
    end

    def head(additional_headers={})
      @conn.head do |req|
        req.url url
        req.headers = (headers || {}).merge(additional_headers)
      end
    end

    def post(payload, additional_headers={})
      @conn.post do |req|
        req.url url
        req.headers = (headers || {}).merge(additional_headers)
        req.body = payload
      end
    end

    def put(payload, additional_headers={})
      @conn.put do |req|
        req.url url
        req.headers = (headers || {}).merge(additional_headers)
        req.body = payload
      end
    end

    def patch(payload, additional_headers={})
      @conn.patch do |req|
        req.url url
        req.headers = (headers || {}).merge(additional_headers)
        req.body = payload
      end
    end

    def delete(additional_headers={})
      @conn.delete do |req|
        req.url url
        req.headers = (headers || {}).merge(additional_headers)
      end
    end

    def to_s
      url
    end

    def user
      options[:user]
    end

    def password
      options[:password]
    end

    def verify_ssl
      options[:verify_ssl]
    end

    def headers
      @conn.headers || {}
    end

    def timeout
      options[:timeout]
    end

    def open_timeout
      options[:open_timeout]
    end

    # Construct a subresource, preserving authentication.
    #
    # Example:
    #
    #   site = RestClient::Resource.new('http://example.com', 'adam', 'mypasswd')
    #   site['posts/1/comments'].post 'Good article.', :content_type => 'text/plain'
    #
    # This is especially useful if you wish to define your site in one place and
    # call it in multiple locations:
    #
    #   def orders
    #     RestClient::Resource.new('http://example.com/orders', 'admin', 'mypasswd')
    #   end
    #
    #   orders.get                     # GET http://example.com/orders
    #   orders['1'].get                # GET http://example.com/orders/1
    #   orders['1/items'].delete       # DELETE http://example.com/orders/1/items
    #
    # Nest resources as far as you want:
    #
    #   site = RestClient::Resource.new('http://example.com')
    #   posts = site['posts']
    #   first_post = posts['1']
    #   comments = first_post['comments']
    #   comments.post 'Hello', :content_type => 'text/plain'
    #
    def [](suburl, &new_block)
      case
        when block_given? then self.class.new(concat_urls(url, suburl), options, &new_block)
        when block        then self.class.new(concat_urls(url, suburl), options, &block)
      else
        self.class.new(concat_urls(url, suburl), options)
      end
    end

    def concat_urls(url, suburl) # :nodoc:
      url = url.to_s
      suburl = suburl.to_s
      if url.slice(-1, 1) == '/' or suburl.slice(0, 1) == '/'
        url + suburl
      else
        "#{url}/#{suburl}"
      end
    end
  end
end
