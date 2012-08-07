module OData
  # Helper methods
  class Helpers
    # Helper to normalize the results of a select result; Ruby 1.9 Hash.select returns a Hash, 1.8 returns an Array
    # This is for Ruby 1.8 support, but should be removed in the future
    def self.normalize_to_hash(val)
      return nil if val.nil?
      (val.is_a? Hash) ? val : Hash[*val.flatten]
    end
  end
end