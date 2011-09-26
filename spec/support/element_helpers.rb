module RSpecSupport
  class ElementHelpers
    def self.string_to_element(element_string)
      Nokogiri::XML.parse(element_string).elements[0]
    end
  end
end