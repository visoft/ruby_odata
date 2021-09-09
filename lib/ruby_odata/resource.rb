module OData
  class Resource
    def initialize(url, options={})
      @conn = Faraday.new(url: url, ssl: { verify: options[:verify_ssl] }) do |faraday|
        faraday.use      :gzip
        faraday.response :raise_error

        faraday.options.timeout      = options[:timeout] if options[:timeout]
        faraday.options.open_timeout = options[:open_timeout] if options[:open_timeout]

        faraday.headers = (faraday.headers || {}).merge(options[:headers] || {})
        faraday.headers = (faraday.headers).merge({
          :accept => '*/*; q=0.5, application/xml',
        })

        faraday.basic_auth options[:user], options[:password] if options[:user] # this adds to headers so must be behind

        yield faraday if block_given?
      end
    end

    def get(url, additional_headers={})
      @conn.get do |req|
        req.url url
        req.headers = (headers || {}).merge(additional_headers)
      end
    end

    def head(url, additional_headers={})
      @conn.head do |req|
        req.url url
        req.headers = (headers || {}).merge(additional_headers)
      end
    end

    def post(url, payload, additional_headers={})
      @conn.post do |req|
        req.url url
        req.headers = (headers || {}).merge(additional_headers)
        req.body = prepare_payload payload
      end
    end

    def put(url, payload, additional_headers={})
      @conn.put do |req|
        req.url url
        req.headers = (headers || {}).merge(additional_headers)
        req.body = prepare_payload payload
      end
    end

    def patch(url, payload, additional_headers={})
      @conn.patch do |req|
        req.url url
        req.headers = (headers || {}).merge(additional_headers)
        req.body = prepare_payload payload
      end
    end

    def delete(url, additional_headers={})
      @conn.delete do |req|
        req.url url
        req.headers = (headers || {}).merge(additional_headers)
      end
    end

    def headers
      @conn.headers || {}
    end

    def prepare_payload payload
      JSON.generate(payload)
    rescue JSON::GeneratorError
      payload
    end
  end
end
