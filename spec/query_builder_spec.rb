require "spec_helper"

module OData
  describe QueryBuilder do
    describe "#initialize" do
      it "handles additional parameters" do
        builder = QueryBuilder.new "Products", { :x=>1, :y=>2 }
        builder.query.should eq "Products?x=1&y=2"
      end
      it "handles empty additional parameters" do
        builder = QueryBuilder.new "Products"
        builder.query.should eq "Products"
      end
    end
    describe "#query" do
      it "should append additional parameters to the end" do
        builder = QueryBuilder.new "Products", { :x=>1, :y=>2 }
        builder.top(10)
        builder.query.should eq "Products?$top=10&x=1&y=2"
      end
      context "#links" do
        it "should properly handle queries for links" do
          builder = QueryBuilder.new "Categories(1)"
          builder.links("Products")
          builder.query.should eq "Categories(1)/$links/Products"
        end
        it "should properly handle queries for links with additional operations" do
          builder = QueryBuilder.new "Categories(1)"
          builder.links("Products")
          builder.top(5)
          builder.query.should eq "Categories(1)/$links/Products?$top=5"
        end
        it "should throw an execption if count was already called on the builder" do
          builder = QueryBuilder.new "Categories(1)"
          builder.count
          lambda { builder.links("Products") }.should raise_error(OData::NotSupportedError, "You cannot call both the `links` method and the `count` method in the same query.")
        end
      end
      context "#count" do
        it "should accept the count method" do
          builder = QueryBuilder.new "Products"
          lambda { builder.count }.should_not raise_error
        end
        it "should properly handle the count method" do
          builder = QueryBuilder.new "Products"
          builder.count
          builder.query.should eq "Products/$count"
        end
        it "should properly handle the count method with additional operators" do
          builder = QueryBuilder.new "Products"
          builder.filter("Name eq 'Widget 1'")
          builder.count
          builder.query.should eq "Products/$count?$filter=Name+eq+%27Widget+1%27"
        end
        it "should throw an execption if links was already called on the builder" do
          builder = QueryBuilder.new "Categories(1)"
          builder.links("Products")
          lambda { builder.count }.should raise_error(OData::NotSupportedError, "You cannot call both the `links` method and the `count` method in the same query.")
        end
      end
    end
  end
end