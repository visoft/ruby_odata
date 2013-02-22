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
      it "should append additional parameters to the end of the query" do
        builder = QueryBuilder.new "Products", { :x=>1, :y=>2 }
        builder.top(10)
        builder.query.should eq "Products?$top=10&x=1&y=2"
      end
    end

    describe "#links" do
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

    describe "#count" do
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

    describe "#navigate" do
      it "should allow a user to drill down into a navigaion property on an initial query" do
        builder = QueryBuilder.new "Genres('Horror Movies')"
        builder.navigate("Titles")
        builder.filter("Name eq 'Halloween'")
        builder.query.should eq "Genres('Horror%20Movies')/Titles?$filter=Name+eq+%27Halloween%27"
      end
      it "should allow for multiple levels of drill down" do
        builder = QueryBuilder.new "Genres('Horror Movies')"
        builder.navigate("Titles('6aBu')")
        builder.navigate("Awards")
        builder.filter("Type eq 'Afi'")
        builder.query.should eq "Genres('Horror%20Movies')/Titles('6aBu')/Awards?$filter=Type+eq+%27Afi%27"
      end
      it "should allow for a drill down plus links" do
        builder = QueryBuilder.new "Genres('Horror Movies')"
        builder.navigate("Titles('6aBu')")
        builder.links("Awards")
        builder.query.should eq "Genres('Horror%20Movies')/Titles('6aBu')/$links/Awards"
      end
      it "should allow for a drill down plus count" do
        builder = QueryBuilder.new "Genres('Horror Movies')"
        builder.navigate("Titles")
        builder.count
        builder.query.should eq "Genres('Horror%20Movies')/Titles/$count"
      end
    end

    describe "additional_parameters" do
      it "should be able to be added at any time" do
        builder = QueryBuilder.new "PollingLocations"
        builder.filter("Address/Zip eq 45693")
        builder.expand("Election")
        builder.additional_params[:foo] = "bar"
        builder.query.should eq "PollingLocations?$expand=Election&$filter=Address%2FZip+eq+45693&foo=bar"
      end

      it "should not overwrite what is already there" do
        builder = QueryBuilder.new "Products", { :x=>1, :y=>2 }
        builder.top(10)
        builder.additional_params[:foo] = "bar"
        builder.query.should eq "Products?$top=10&foo=bar&x=1&y=2"
      end
    end

    describe "#query" do
      it "should encode spaces in IDs" do
        builder = QueryBuilder.new "Categories('Cool Stuff')"
        builder.query.should eq "Categories('Cool%20Stuff')"
      end
    end
  end
end