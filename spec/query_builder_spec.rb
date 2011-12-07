require 'spec_helper'

module OData
  describe QueryBuilder do
    describe "#initialize" do
      it "handles additional parameters" do        
        builder = QueryBuilder.new 'Products', { :x=>1, :y=>2 }
        builder.query.should eq "Products?x=1&y=2"
      end
      it "handles empty additional parameters" do        
        builder = QueryBuilder.new 'Products'
        builder.query.should eq "Products"
      end      
    end
    describe "#query" do
      it "should append additional parameters to the end" do
        builder = QueryBuilder.new 'Products', { :x=>1, :y=>2 }
        builder.top(10)
        builder.query.should eq "Products?$top=10&x=1&y=2"
      end
      it "should properly handle queries for links" do
        builder = QueryBuilder.new 'Categories(1)'
        builder.links('Products')
        builder.query.should eq "Categories(1)/$links/Products"
      end
      it "should properly handle queries for links with additional operations" do
        builder = QueryBuilder.new 'Categories(1)'
        builder.links('Products')
        builder.top(5)
        builder.query.should eq "Categories(1)/$links/Products?$top=5"
      end
    end
  end
end