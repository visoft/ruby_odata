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
    end
  end
end