module OData
  # Helper methods
  class Helpers
    # Helper to normalize the results of a select result; Ruby 1.9 Hash.select returns a Hash, 1.8 returns an Array
    # This is for Ruby 1.8 support, but should be removed in the future
    def self.normalize_to_hash(val)
      return nil if val.nil?
      (val.is_a? Hash) ? val : Hash[*val.flatten]
    end

    # Wrapper for URI escaping that switches between URI::Parser#escape and
    # URI.escape for 1.9-compatibility (thanks FakeWeb https://github.com/chrisk/fakeweb/blob/master/lib/fake_web/utility.rb#L40)
    def self.uri_escape(*args)
      if URI.const_defined?(:Parser)
        URI::Parser.new.escape(*args)
      else
        URI.escape(*args)
      end
    end

    # Nokogiri changed how it handles namespaced attributes with v1.5.1, this is for backwards compatibility to >= 1.4.2
    # Nokogiri now >=1.5.1 requires the namespace prefix is used
    def self.get_namespaced_attribute(node, attr_name, prefix)
      return node["#{prefix}:#{attr_name}"] || node[attr_name]
    end
  end
end