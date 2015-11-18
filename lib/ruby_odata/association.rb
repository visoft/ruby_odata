module OData
  # Internal class used to represent object associations
  class Association

    attr_reader :name, :namespace, :relationship, :from_role, :to_role

    def initialize(nav_prop_element, edmx)
      @edmx = edmx

      # Get the edm namespace because it varies by version
      root = @edmx.xpath("/edmx:Edmx").first
      @version = root['Version'].to_i
      edmxurl = root.namespaces['xmlns:edmx']
      ds = @edmx.xpath("edmx:Edmx/edmx:DataServices/*", "edmx" => edmxurl).first
      edm_ns = ds.namespaces['xmlns'].to_s
      @edmx_namespaces = { "edmx" => edmxurl, "edm" => edm_ns }
      parse_nav_prop(nav_prop_element)
    end

    private

    def parse_nav_prop(element)
      if @version >= 4
      else
        @relationship = element['Relationship']
        relationship_parts = @relationship.split('.')
        @name = relationship_parts.pop
        @namespace = relationship_parts.join('.')
        @from_role = role_hash(@name, element['FromRole'])
        @to_role = role_hash(@name, element['ToRole'])
      end
    end

    def role_hash(association_name, role_name)
      # Find the end role based on the assocation name
      role_xpath = "/edmx:Edmx/edmx:DataServices/edm:Schema[@Namespace='#{@namespace}']/edm:Association[@Name='#{association_name}']/edm:End[@Role='#{role_name}']"
      role_element = @edmx.xpath(role_xpath, @edmx_namespaces).first
      { role_name => {
          :edmx_type => "#{role_element['Type']}",
          :multiplicity => "#{role_element['Multiplicity']}"
      }}
    end
  end
end