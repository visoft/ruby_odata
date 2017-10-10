require 'spec_helper'

module OData
  describe Service do

    after(:each) do
      remove_classes @service
    end

    describe "#initialize" do
      it "truncates passed in end slash from uri when making the request" do
        # Required for the build_classes method
        stub_request(:get, "http://test.com/test.svc/$metadata").
          with(:headers => DEFAULT_HEADERS).
          to_return(:status => 200, :body => Fixtures.load("edmx_empty.xml"), :headers => {})

        @service =OData::Service.new "http://test.com/test.svc/"
      end
      it "doesn't error with lowercase entities" do
        # Required for the build_classes method
        stub_request(:get, "http://test.com/test.svc/$metadata").
          with(:headers => DEFAULT_HEADERS).
          to_return(:status => 200, :body => Fixtures.load("edmx_lowercase.xml"), :headers => {})

        expect { @service = OData::Service.new "http://test.com/test.svc" }.not_to raise_error
      end

      describe "additional query string parameters" do
        before(:each) do
          # Required for the build_classes method
          stub_request(:get, /http:\/\/test\.com\/test\.svc\/\$metadata(?:\?.+)?/).
            with(:headers => DEFAULT_HEADERS).
            to_return(:status => 200, :body => Fixtures.load("edmx_empty.xml"), :headers => {})
        end
        it "should accept additional query string parameters" do
          @service =OData::Service.new "http://test.com/test.svc/", { :additional_params => { :x=>1, :y=>2 } }
          @service.options[:additional_params].should eq Hash[:x=>1, :y=>2]
        end
        it "should call the correct metadata uri when additional_params are passed in" do
          @service =OData::Service.new "http://test.com/test.svc/", { :additional_params => { :x => 1, :y => 2 } }
          a_request(:get, "http://test.com/test.svc/$metadata?x=1&y=2").should have_been_made
        end
      end

      describe "rest-client options" do
        before(:each) do
          # Required for the build_classes method
          stub_request(:get, /http:\/\/test\.com\/test\.svc\/\$metadata(?:\?.+)?/).
            with(:headers => DEFAULT_HEADERS).
            to_return(:status => 200, :body => Fixtures.load("edmx_empty.xml"), :headers => {})
        end
        it "should accept in options that will be passed to the rest-client lib" do
          @service =OData::Service.new "http://test.com/test.svc/", { :rest_options => { :ssl_ca_file => "ca_certificate.pem" } }
          @service.options[:rest_options].should eq Hash[:ssl_ca_file => "ca_certificate.pem"]
        end
        it "should merge the rest options with the built in options" do
          @service =OData::Service.new "http://test.com/test.svc/", { :rest_options => { :ssl_ca_file => "ca_certificate.pem" } }
          @service.instance_variable_get(:@rest_options).should eq Hash[:verify_ssl => 1, :user => nil, :password => nil, :ssl_ca_file => "ca_certificate.pem"]
        end
      end
    end

    describe "additional query string parameters" do
      before(:each) do
        # Required for the build_classes method
        stub_request(:any, /http:\/\/test\.com\/test\.svc(?:.*)/).
          with(:headers => DEFAULT_HEADERS).
          to_return(:status => 200, :body => Fixtures.load("/sap/edmx_sap_demo_flight.xml"), :headers => {})
      end
      it "should pass the parameters as part of a query" do
        @service =OData::Service.new "http://test.com/test.svc/", { :additional_params => { :x=>1, :y=>2 } }
        @service.flight_dataCollection
        @service.execute
        a_request(:get, "http://test.com/test.svc/flight_dataCollection?x=1&y=2").should have_been_made
      end
      it "should pass the parameters as part of a save" do
        @service =OData::Service.new "http://test.com/test.svc/", { :additional_params => { :x=>1, :y=>2 } }
        new_flight = ZDemoFlight.new
        @service.AddToflight_dataCollection(new_flight)
        @service.save_changes
        a_request(:post, "http://test.com/test.svc/flight_dataCollection?x=1&y=2").should have_been_made
      end
      it "should pass the parameters as part of an update" do
        @service =OData::Service.new "http://test.com/test.svc/", { :additional_params => { :x=>1, :y=>2 } }
        existing_flight = ZDemoFlight.new
        existing_flight.__metadata = { :uri => "http://test.com/test.svc/flight_dataCollection/1" }
        @service.update_object(existing_flight)
        @service.save_changes
        a_request(:put, "http://test.com/test.svc/flight_dataCollection/1?x=1&y=2").should have_been_made
      end
      it "should pass the parameters as part of a delete" do
        @service =OData::Service.new "http://test.com/test.svc/", { :additional_params => { :x=>1, :y=>2 } }
        existing_flight = ZDemoFlight.new
        existing_flight.__metadata = { :uri => "http://test.com/test.svc/flight_dataCollection/1" }
        @service.delete_object(existing_flight)
        @service.save_changes
        a_request(:delete, "http://test.com/test.svc/flight_dataCollection/1?x=1&y=2").should have_been_made
      end
      it "should pass the parameters as part of a batch save" do
        @service =OData::Service.new "http://test.com/test.svc/", { :additional_params => { :x=>1, :y=>2 } }
        new_flight = ZDemoFlight.new
        @service.AddToflight_dataCollection(new_flight)
        new_flight2 = ZDemoFlight.new
        @service.AddToflight_dataCollection(new_flight2)
        @service.save_changes
        a_request(:post, "http://test.com/test.svc/$batch?x=1&y=2").should have_been_made
      end
      it "should pass the parameters as part of an add link" do
        @service =OData::Service.new "http://test.com/test.svc/", { :additional_params => { :x=>1, :y=>2 } }
        existing_flight1 = ZDemoFlight.new
        existing_flight1.__metadata = { :uri => "http://test.com/test.svc/flight_dataCollection/1" }
        existing_flight2 = ZDemoFlight.new
        existing_flight2.__metadata = { :uri => "http://test.com/test.svc/flight_dataCollection/2" }
        @service.add_link(existing_flight1, "flight_data_r", existing_flight2)
        @service.save_changes
        a_request(:post, "http://test.com/test.svc/flight_dataCollection/1/$links/flight_data_r?x=1&y=2").should have_been_made
      end
      it "should pass the parameters as part of a function import with a parameter" do
        @service =OData::Service.new "http://test.com/test.svc/", { :additional_params => { :x=>1, :y=>2 } }
        @service.get_flight(1)
        a_request(:get, "http://test.com/test.svc/get_flight?id=1&x=1&y=2").should have_been_made
      end
      it "should pass the parameters as part of a function import without parameters" do
        @service =OData::Service.new "http://test.com/test.svc/", { :additional_params => { :x=>1, :y=>2 } }
        @service.get_top_flight
        a_request(:get, "http://test.com/test.svc/get_top_flight?x=1&y=2").should have_been_made
      end
    end

    describe "exception handling" do
      before(:each) do
        stub_request(:get, "http://test.com/test.svc/$metadata").
          with(:headers => DEFAULT_HEADERS).
          to_return(:status => 200, :body => Fixtures.load("sample_service/edmx_categories_products.xml"), :headers => {})

        stub_request(:get, "http://test.com/test.svc/Categories?$select=Price").
          with(:headers => DEFAULT_HEADERS).
          to_return(:status => 400, :body => Fixtures.load("error_without_message.xml"), :headers => {})
      end

      it "includes a generic message if the error is not in the response" do
        @service =OData::Service.new "http://test.com/test.svc/"
        @service.Categories.select "Price"
        expect { @service.execute }.to raise_error(OData::ServiceError) { |error|
          error.http_code.should eq 400
          error.message.should eq "Server returned error but no message."
        }
      end
    end

    describe "lowercase collections" do
      before(:each) do
        # Required for the build_classes method
        stub_request(:get, "http://test.com/test.svc/$metadata").
          with(:headers => DEFAULT_HEADERS).
          to_return(:status => 200, :body => Fixtures.load("edmx_lowercase.xml"), :headers => {})
      end

      it "should respond_to a lowercase collection" do
        @service =OData::Service.new "http://test.com/test.svc"
        expect(@service.respond_to?('acronyms')).to eq true
      end

      it "should allow a lowercase collections to be queried" do
        @service =OData::Service.new "http://test.com/test.svc"
        lambda { @service.send('acronyms') }.should_not raise_error
      end
    end


    describe "collections, objects, metadata etc" do
      before(:each) do
        # Metadata
        stub_request(:get, "http://test.com/test.svc/$metadata").
          with(:headers => DEFAULT_HEADERS).
          to_return(:status => 200, :body => Fixtures.load("feed_customization/edmx_feed_customization.xml"), :headers => {})

        # Content - Products
        stub_request(:get, /http:\/\/test\.com\/test\.svc\/Products(?:.*)/).
          with(:headers => DEFAULT_HEADERS).
          to_return(:status => 200, :body => Fixtures.load("feed_customization/result_feed_customization_products_expand.xml"), :headers => {})

        # Content - Categories expanded Products
        stub_request(:get, /http:\/\/test\.com\/test\.svc\/Categories(?:.*)/).
          with(:headers => DEFAULT_HEADERS).
          to_return(:status => 200, :body => Fixtures.load("feed_customization/result_feed_customization_categories_expand.xml"), :headers => {})
      end

      describe "handling feed customizations" do
        describe "property metadata" do
          it "should fill the class_metadata hash" do
            @service =OData::Service.new "http://test.com/test.svc/"
            @service.class_metadata.should_not be_empty
          end
          it "should add a key (based on the name) for each property class_metadata hash" do
            @service =OData::Service.new "http://test.com/test.svc/"
            @service.class_metadata['Product'].should have_key 'ID'
            @service.class_metadata['Product'].should have_key 'Name'
            @service.class_metadata['Product'].should have_key 'Description'
          end
          it "should have a PropertyMetadata object for each property class_metadata hash" do
            @service =OData::Service.new "http://test.com/test.svc/"
            @service.class_metadata['Product']['ID'].should be_a OData::PropertyMetadata
            @service.class_metadata['Product']['Name'].should be_a OData::PropertyMetadata
            @service.class_metadata['Product']['Description'].should be_a OData::PropertyMetadata
          end
          it "should have the correct PropertyMetadata object for Id" do
            @service =OData::Service.new "http://test.com/test.svc/"
            meta = @service.class_metadata['Product']['ID']
            meta.name.should eq 'ID'
            meta.type.should eq 'Edm.Int32'
            meta.nullable.should eq false
            meta.fc_target_path.should be_nil
            meta.fc_keep_in_content.should be_nil
          end
          it "should have the correct PropertyMetadata object for Name" do
            @service =OData::Service.new "http://test.com/test.svc/"
            meta = @service.class_metadata['Product']['Name']
            meta.name.should eq 'Name'
            meta.type.should eq 'Edm.String'
            meta.nullable.should eq true
            meta.fc_target_path.should eq "SyndicationTitle"
            meta.fc_keep_in_content.should eq false
          end
          it "should have the correct PropertyMetadata object for Description" do
            @service =OData::Service.new "http://test.com/test.svc/"
            meta = @service.class_metadata['Product']['Description']
            meta.name.should eq 'Description'
            meta.type.should eq 'Edm.String'
            meta.nullable.should eq true
            meta.fc_target_path.should eq "SyndicationSummary"
            meta.fc_keep_in_content.should eq false
          end
        end

        describe "single class" do
          it "should handle properties where a property is represented in the syndication title instead of the properties collection" do
            @service =OData::Service.new "http://test.com/test.svc/"
            @service.Products
            results = @service.execute
            results.first.Name.should eq "Bread"
          end
          it "should handle properties where a property is represented in the syndication summary instead of the properties collection" do
            @service =OData::Service.new "http://test.com/test.svc/"
            @service.Products
            results = @service.execute
            results.first.Description.should eq "Whole grain bread"
          end
        end

        describe "expanded inline class" do
          it "should handle properties where a property is represented in the syndication title instead of the properties collection" do
            @service =OData::Service.new "http://test.com/test.svc/"
            @service.Categories
            results = @service.execute

            beverages = results[1]

            milk = beverages.Products.first
            milk.Name.should eq "Milk"
            milk.Description.should eq "Low fat milk"

            lemonade = beverages.Products.last
            lemonade.Name.should eq "Pink Lemonade"
            lemonade.Description.should eq "36 Ounce Cans (Pack of 3)"
          end
        end
      end

      describe "handling inline collections/properties" do
        it "should make plural named properties arrays and not a single class" do
          @service =OData::Service.new "http://test.com/test.svc/"
          @service.Categories
          results = @service.execute
          food = results[0]

          food.Products.should be_an Array
        end

        it "should not make an array if the navigation property name is singular" do
          @service =OData::Service.new "http://test.com/test.svc/"
          @service.Products
          results = @service.execute
          product = results.first
          product.Category.should_not be_an Array
        end
      end

      describe "navigation properties" do
        it "should fill in PropertyMetadata for navigation properties" do
          @service =OData::Service.new "http://test.com/test.svc/"
          @service.class_metadata['Product'].should have_key 'Category'
        end
      end
    end

    describe "single layer inheritance" do
      before(:each) do
        # Metadata
        stub_request(:get, "http://test.com/test.svc/$metadata").
          with(:headers => DEFAULT_HEADERS).
          to_return(:status => 200, :body => Fixtures.load("inheritance/edmx_pluralsight.xml"), :headers => {})

        # Content - Courses
        stub_request(:get, /http:\/\/test\.com\/test\.svc\/Courses(?:.*)/).
          with(:headers => DEFAULT_HEADERS).
          to_return(:status => 200, :body => Fixtures.load("inheritance/result_pluralsight_courses.xml"), :headers => {})
      end

      it "should build all inherited attributes" do
        @service = OData::Service.new "http://test.com/test.svc/"
        methods = Course.instance_methods.reject {|m| Object.methods.index(m)}

        # Ruby 1.9 uses symbols, and 1.8 uses strings, so this normalizes the data
        methods.map! {|m| m.to_sym}

        methods.should include(:Title)
        methods.should include(:Description)
        methods.should include(:VideoLength)
        methods.should include(:Category)

        methods.should include(:Title=)
        methods.should include(:Description=)
        methods.should include(:VideoLength=)
        methods.should include(:Category=)
      end

      it "should not build abstract classes" do
        @service = OData::Service.new "http://test.com/test.svc/"
        defined?(ModelItemBase).should eq nil
      end

      it "should fill inherited properties" do
        @service =OData::Service.new "http://test.com/test.svc/"
        @service.Courses
        courses = @service.execute
        course = courses.first
        course.Title.should_not be_nil
        course.Description.should_not be_nil
        course.VideoLength.should_not be_nil
        course.Category.should_not be_nil
      end
    end

    describe "handling partial collections" do
      before(:each) do
        # Metadata
        stub_request(:get, "http://test.com/test.svc/$metadata").
          with(:headers => DEFAULT_HEADERS).
          to_return(:status => 200, :body => Fixtures.load("partial/partial_feed_metadata.xml"), :headers => {})

        # Content - Partial
        stub_request(:get, "http://test.com/test.svc/Partials").
          with(:headers => DEFAULT_HEADERS).
          to_return(:status => 200, :body => Fixtures.load("partial/partial_feed_part_1.xml"), :headers => {})

        stub_request(:get, "http://test.com/test.svc/Partials?$skiptoken='ERNSH'").
          with(:headers => DEFAULT_HEADERS).
          to_return(:status => 200, :body => Fixtures.load("partial/partial_feed_part_2.xml"), :headers => {})

        stub_request(:get, "http://test.com/test.svc/Partials?$skiptoken='ERNSH2'").
          with(:headers => DEFAULT_HEADERS).
          to_return(:status => 200, :body => Fixtures.load("partial/partial_feed_part_3.xml"), :headers => {})

      end

      it "should return the whole collection by default" do
        @service =OData::Service.new "http://test.com/test.svc/"
        @service.Partials
        results = @service.execute
        results.count.should eq 3
      end

      it "should return only the partial when specified by options" do
        @service =OData::Service.new("http://test.com/test.svc/", :eager_partial => false)
        @service.Partials
        results = @service.execute
        results.count.should eq 1
        @service.should be_partial
        while @service.partial?
          results.concat @service.next
        end
        results.count.should eq 3
      end

      context "with additional_params" do
        before(:each) do
          stub_request(:get, "http://test.com/test.svc/$metadata?extra_param=value").
            with(:headers => DEFAULT_HEADERS).
            to_return(:status => 200, :body => Fixtures.load("partial/partial_feed_metadata.xml"), :headers => {})

          stub_request(:get, "http://test.com/test.svc/Partials?extra_param=value").
            with(:headers => DEFAULT_HEADERS).
            to_return(:status => 200, :body => Fixtures.load("partial/partial_feed_part_1.xml"), :headers => {})

          stub_request(:get, "http://test.com/test.svc/Partials?$skiptoken='ERNSH'&extra_param=value").
            with(:headers => DEFAULT_HEADERS).
            to_return(:status => 200, :body => Fixtures.load("partial/partial_feed_part_2.xml"), :headers => {})
        end

        it "should persist the additional parameters for the next call" do
          @service =OData::Service.new("http://test.com/test.svc/", :eager_partial => false, :additional_params => { :extra_param => 'value' })
          @service.Partials
          @service.execute
          @service.next

          a_request(:get, "http://test.com/test.svc/Partials?$skiptoken='ERNSH'&extra_param=value").should have_been_made
        end
      end
    end

    describe "link queries" do
      before(:each) do
        # Required for the build_classes method
        stub_request(:get, /http:\/\/test\.com\/test\.svc\/\$metadata(?:\?.+)?/).
          with(:headers => DEFAULT_HEADERS).
          to_return(:status => 200, :body => Fixtures.load("sample_service/edmx_categories_products.xml"), :headers => {})

        stub_request(:get, "http://test.com/test.svc/Categories(1)/$links/Products").
          with(:headers => DEFAULT_HEADERS).
          to_return(:status => 200, :body => Fixtures.load("links/result_links_query.xml"), :headers => {})
      end
      it "should be able to parse the results of a links query" do
        @service =OData::Service.new "http://test.com/test.svc/"
        @service.Categories(1).links('Products')
        results = @service.execute
        results.count.should eq 3
        results.first.should be_a_kind_of(URI)
        results[0].path.should eq "/SampleService/RubyOData.svc/Products(1)"
        results[1].path.should eq "/SampleService/RubyOData.svc/Products(2)"
        results[2].path.should eq "/SampleService/RubyOData.svc/Products(3)"
      end
    end




    describe "handling of nested expands" do
      before(:each) do
        stub_request(:get, "http://test.com/test.svc/$metadata").
          with(:headers => DEFAULT_HEADERS).
          to_return(:status => 200, :body => Fixtures.load("nested_expands/edmx_northwind.xml"), :headers => {})

        stub_request(:get, "http://test.com/test.svc/Products?$expand=Category,Category/Products&$top=2").
          with(:headers => DEFAULT_HEADERS).
          to_return(:status => 200, :body => Fixtures.load("nested_expands/northwind_products_category_expands.xml"), :headers => {})
      end
      after(:each) do
        #Object.send(:remove_const, 'Product') if Object.const_defined? 'Product'
      end

      it "should successfully parse the results" do
        @service =OData::Service.new "http://test.com/test.svc", { :namespace => "NW" }
        @service.Products.expand('Category').expand('Category/Products').top(2)
        lambda { @service.execute }.should_not raise_exception
      end

      it "should successfully parse a Category as a Category" do
        @service =OData::Service.new "http://test.com/test.svc", { :namespace => "NW" }
        @service.Products.expand('Category').expand('Category/Products').top(2)
        products = @service.execute
        products.first.Category.should be_a_kind_of(NW::Category)
      end

      it "should successfully parse the Category properties" do
        @service =OData::Service.new "http://test.com/test.svc", { :namespace => "NW" }
        @service.Products.expand('Category').expand('Category/Products').top(2)
        products = @service.execute
        products.first.Category.CategoryID.should eq 1
      end

      it "should successfully parse the Category children Products" do
        @service =OData::Service.new "http://test.com/test.svc", { :namespace => "NW" }
        @service.Products.expand('Category').expand('Category/Products').top(2)
        products = @service.execute
        products.first.Category.Products.length.should eq 12
      end

      it "should successfully parse the Category's child Product properties" do
        @service =OData::Service.new "http://test.com/test.svc", { :namespace => "NW" }
        @service.Products.expand('Category').expand('Category/Products').top(2)
        products = @service.execute
        products.first.Category.Products.first.ProductName.should eq "Chai"
      end
    end

    describe "handling of custom select queries" do

      context "when results are found" do
        before(:each) do
          stub_request(:get, "http://test.com/test.svc/$metadata").
            with(:headers => DEFAULT_HEADERS).
            to_return(:status => 200, :body => Fixtures.load("/sample_service/edmx_categories_products.xml"), :headers => {})

          stub_request(:get, "http://test.com/test.svc/Products?$select=Name,Price").
            with(:headers => DEFAULT_HEADERS).
            to_return(:status => 200, :body => Fixtures.load("/sample_service/result_select_products_name_price.xml"), :headers => {})
        end

        before(:each) do
          @service =OData::Service.new "http://test.com/test.svc/"
          @service.Products.select "Name", "Price"
          @result = @service.execute
        end

        it "returns an Array og Products" do
          expect(@result).to  be_an Array
          expect(@result).not_to be_empty
          expect(@result.first).to be_a Product
        end
      end

      context "when there isn't a property by the name specified" do
        before(:each) do
          stub_request(:get, "http://test.com/test.svc/$metadata").
            with(:headers => DEFAULT_HEADERS).
            to_return(:status => 200, :body => Fixtures.load("sample_service/edmx_categories_products.xml"), :headers => {})

          stub_request(:get, "http://test.com/test.svc/Categories?$select=Price").
            with(:headers => DEFAULT_HEADERS).
            to_return(:status => 400, :body => Fixtures.load("sample_service/result_select_categories_no_property.xml"), :headers => {})
        end

        it "raises an exception" do
          @service =OData::Service.new "http://test.com/test.svc/"
          @service.Categories.select "Price"
          expect { @service.execute }.to raise_error(OData::ServiceError) { |error|
            error.http_code.should eq 400
            error.message.should eq "Type 'RubyODataService.Category' does not have a property named 'Price' or there is no type with 'Price' name."
          }
        end
      end

      context "when a property requires $expand to traverse", focus: true do
        before(:each) do
          stub_request(:get, "http://test.com/test.svc/$metadata").
            with(:headers => DEFAULT_HEADERS).
            to_return(:status => 200, :body => Fixtures.load("sample_service/edmx_categories_products.xml"), :headers => {})

          stub_request(:get, "http://test.com/test.svc/Categories?$select=Name,Products/Name").
            with(:headers => DEFAULT_HEADERS).
            to_return(:status => 400, :body => Fixtures.load("sample_service/result_select_categories_travsing_no_expand.xml"), :headers => {})

          stub_request(:get, "http://test.com/test.svc/Categories?$select=Name,Products/Name&$expand=Products").
            with(:headers => DEFAULT_HEADERS).
            to_return(:status => 200, :body => Fixtures.load("sample_service/result_select_categories_expand.xml"), :headers => {})

          stub_request(:get, "http://test.com/test.svc/Categories").
            with(:headers => DEFAULT_HEADERS).
            to_return(:status => 200, :body => Fixtures.load("sample_service/result_select_categories_expand.xml"), :headers => {})

        end

        it "retursn Categoris" do
          @service =OData::Service.new "http://test.com/test.svc/"
          @service.Categories
          c = @service.execute
        end

        it "doesn't error" do
          @service =OData::Service.new "http://test.com/test.svc/"
          @service.Categories.select "Name", "Products/Name"
          expect { @service.execute }.to_not raise_error
        end

        it "returns the classes with the properties filled in" do
          @service =OData::Service.new "http://test.com/test.svc/"
          @service.Categories.select "Name", "Products/Name"
          results = @service.execute
          category = results.first
          category.Name.should eq "Category 0001"
          product = category.Products.first
          product.Name.should eq "Widget 0001"
        end
      end
    end
  end

end
