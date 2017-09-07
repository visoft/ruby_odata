require 'spec_helper'

module OData
  describe Service do
    describe "#initialize" do
      it "truncates passed in end slash from uri when making the request" do
        # Required for the build_classes method
        stub_request(:get, "http://test.com/test.svc/$metadata").
          with(:headers => DEFAULT_HEADERS).
          to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/edmx_empty.xml", __FILE__)), :headers => {})

        svc = OData::Service.new "http://test.com/test.svc/"
      end
      it "doesn't error with lowercase entities" do
        # Required for the build_classes method
        stub_request(:get, "http://test.com/test.svc/$metadata").
          with(:headers => DEFAULT_HEADERS).
          to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/edmx_lowercase.xml", __FILE__)), :headers => {})

        lambda { OData::Service.new "http://test.com/test.svc" }.should_not raise_error
      end

      describe "additional query string parameters" do
        before(:each) do
          # Required for the build_classes method
          stub_request(:get, /http:\/\/test\.com\/test\.svc\/\$metadata(?:\?.+)?/).
            with(:headers => DEFAULT_HEADERS).
            to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/edmx_empty.xml", __FILE__)), :headers => {})
        end
        it "should accept additional query string parameters" do
          svc = OData::Service.new "http://test.com/test.svc/", { :additional_params => { :x=>1, :y=>2 } }
          svc.options[:additional_params].should eq Hash[:x=>1, :y=>2]
        end
        it "should call the correct metadata uri when additional_params are passed in" do
          svc = OData::Service.new "http://test.com/test.svc/", { :additional_params => { :x => 1, :y => 2 } }
          a_request(:get, "http://test.com/test.svc/$metadata?x=1&y=2").should have_been_made
        end
      end

      describe "rest-client options" do
        before(:each) do
          # Required for the build_classes method
          stub_request(:get, /http:\/\/test\.com\/test\.svc\/\$metadata(?:\?.+)?/).
            with(:headers => DEFAULT_HEADERS).
            to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/edmx_empty.xml", __FILE__)), :headers => {})
        end
        it "should accept in options that will be passed to the rest-client lib" do
          svc = OData::Service.new "http://test.com/test.svc/", { :rest_options => { :ssl_ca_file => "ca_certificate.pem" } }
          svc.options[:rest_options].should eq Hash[:ssl_ca_file => "ca_certificate.pem"]
        end
        it "should merge the rest options with the built in options" do
          svc = OData::Service.new "http://test.com/test.svc/", { :rest_options => { :ssl_ca_file => "ca_certificate.pem" } }
          svc.instance_variable_get(:@rest_options).should eq Hash[:verify_ssl => 1, :user => nil, :password => nil, :ssl_ca_file => "ca_certificate.pem"]
        end
      end
    end
    describe "additional query string parameters" do
      before(:each) do
        # Required for the build_classes method
        stub_request(:any, /http:\/\/test\.com\/test\.svc(?:.*)/).
          with(:headers => DEFAULT_HEADERS).
          to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/sap/edmx_sap_demo_flight.xml", __FILE__)), :headers => {})
      end
      it "should pass the parameters as part of a query" do
        svc = OData::Service.new "http://test.com/test.svc/", { :additional_params => { :x=>1, :y=>2 } }
        svc.flight_dataCollection
        svc.execute
        a_request(:get, "http://test.com/test.svc/flight_dataCollection?x=1&y=2").should have_been_made
      end
      it "should pass the parameters as part of a save" do
        svc = OData::Service.new "http://test.com/test.svc/", { :additional_params => { :x=>1, :y=>2 } }
        new_flight = ZDemoFlight.new
        svc.AddToflight_dataCollection(new_flight)
        svc.save_changes
        a_request(:post, "http://test.com/test.svc/flight_dataCollection?x=1&y=2").should have_been_made
      end
      it "should pass the parameters as part of an update" do
        svc = OData::Service.new "http://test.com/test.svc/", { :additional_params => { :x=>1, :y=>2 } }
        existing_flight = ZDemoFlight.new
        existing_flight.__metadata = { :uri => "http://test.com/test.svc/flight_dataCollection/1" }
        svc.update_object(existing_flight)
        svc.save_changes
        a_request(:put, "http://test.com/test.svc/flight_dataCollection/1?x=1&y=2").should have_been_made
      end
      it "should pass the parameters as part of a delete" do
        svc = OData::Service.new "http://test.com/test.svc/", { :additional_params => { :x=>1, :y=>2 } }
        existing_flight = ZDemoFlight.new
        existing_flight.__metadata = { :uri => "http://test.com/test.svc/flight_dataCollection/1" }
        svc.delete_object(existing_flight)
        svc.save_changes
        a_request(:delete, "http://test.com/test.svc/flight_dataCollection/1?x=1&y=2").should have_been_made
      end
      it "should pass the parameters as part of a batch save" do
        svc = OData::Service.new "http://test.com/test.svc/", { :additional_params => { :x=>1, :y=>2 } }
        new_flight = ZDemoFlight.new
        svc.AddToflight_dataCollection(new_flight)
        new_flight2 = ZDemoFlight.new
        svc.AddToflight_dataCollection(new_flight2)
        svc.save_changes
        a_request(:post, "http://test.com/test.svc/$batch?x=1&y=2").should have_been_made
      end
      it "should pass the parameters as part of an add link" do
        svc = OData::Service.new "http://test.com/test.svc/", { :additional_params => { :x=>1, :y=>2 } }
        existing_flight1 = ZDemoFlight.new
        existing_flight1.__metadata = { :uri => "http://test.com/test.svc/flight_dataCollection/1" }
        existing_flight2 = ZDemoFlight.new
        existing_flight2.__metadata = { :uri => "http://test.com/test.svc/flight_dataCollection/2" }
        svc.add_link(existing_flight1, "flight_data_r", existing_flight2)
        svc.save_changes
        a_request(:post, "http://test.com/test.svc/flight_dataCollection/1/$links/flight_data_r?x=1&y=2").should have_been_made
      end
      it "should pass the parameters as part of a function import with a parameter" do
        svc = OData::Service.new "http://test.com/test.svc/", { :additional_params => { :x=>1, :y=>2 } }
        svc.get_flight(1)
        a_request(:get, "http://test.com/test.svc/get_flight?id=1&x=1&y=2").should have_been_made
      end
      it "should pass the parameters as part of a function import without parameters" do
        svc = OData::Service.new "http://test.com/test.svc/", { :additional_params => { :x=>1, :y=>2 } }
        svc.get_top_flight
        a_request(:get, "http://test.com/test.svc/get_top_flight?x=1&y=2").should have_been_made
      end
    end

    describe "exception handling" do
      before(:each) do
        stub_request(:get, "http://test.com/test.svc/$metadata").
          with(:headers => DEFAULT_HEADERS).
          to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/sample_service/edmx_categories_products.xml", __FILE__)), :headers => {})

        stub_request(:get, "http://test.com/test.svc/Categories?$select=Price").
          with(:headers => DEFAULT_HEADERS).
          to_return(:status => 400, :body => File.new(File.expand_path("../fixtures/error_without_message.xml", __FILE__)), :headers => {})
      end

      it "includes a generic message if the error is not in the response" do
        svc = OData::Service.new "http://test.com/test.svc/"
        svc.Categories.select "Price"
        expect { svc.execute }.to raise_error(OData::ServiceError) { |error|
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
          to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/edmx_lowercase.xml", __FILE__)), :headers => {})
      end

      it "should respond_to a lowercase collection" do
        svc = OData::Service.new "http://test.com/test.svc"
        expect(svc.respond_to?('acronyms')).to eq true
      end

      it "should allow a lowercase collections to be queried" do
        svc = OData::Service.new "http://test.com/test.svc"
        lambda { svc.send('acronyms') }.should_not raise_error
      end
    end


    describe "collections, objects, metadata etc" do
      before(:each) do
        # Metadata
        stub_request(:get, "http://test.com/test.svc/$metadata").
          with(:headers => DEFAULT_HEADERS).
          to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/feed_customization/edmx_feed_customization.xml", __FILE__)), :headers => {})

        # Content - Products
        stub_request(:get, /http:\/\/test\.com\/test\.svc\/Products(?:.*)/).
          with(:headers => DEFAULT_HEADERS).
          to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/feed_customization/result_feed_customization_products_expand.xml", __FILE__)), :headers => {})

        # Content - Categories expanded Products
        stub_request(:get, /http:\/\/test\.com\/test\.svc\/Categories(?:.*)/).
          with(:headers => DEFAULT_HEADERS).
          to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/feed_customization/result_feed_customization_categories_expand.xml", __FILE__)), :headers => {})
      end
      after(:each) do
        Object.send(:remove_const, 'Product')
        Object.send(:remove_const, 'Category')
      end
      describe "handling feed customizations" do
        describe "property metadata" do
          it "should fill the class_metadata hash" do
            svc = OData::Service.new "http://test.com/test.svc/"
            svc.class_metadata.should_not be_empty
          end
          it "should add a key (based on the name) for each property class_metadata hash" do
            svc = OData::Service.new "http://test.com/test.svc/"
            svc.class_metadata['Product'].should have_key 'ID'
            svc.class_metadata['Product'].should have_key 'Name'
            svc.class_metadata['Product'].should have_key 'Description'
          end
          it "should have a PropertyMetadata object for each property class_metadata hash" do
            svc = OData::Service.new "http://test.com/test.svc/"
            svc.class_metadata['Product']['ID'].should be_a OData::PropertyMetadata
            svc.class_metadata['Product']['Name'].should be_a OData::PropertyMetadata
            svc.class_metadata['Product']['Description'].should be_a OData::PropertyMetadata
          end
          it "should have the correct PropertyMetadata object for Id" do
            svc = OData::Service.new "http://test.com/test.svc/"
            meta = svc.class_metadata['Product']['ID']
            meta.name.should eq 'ID'
            meta.type.should eq 'Edm.Int32'
            meta.nullable.should eq false
            meta.fc_target_path.should be_nil
            meta.fc_keep_in_content.should be_nil
          end
          it "should have the correct PropertyMetadata object for Name" do
            svc = OData::Service.new "http://test.com/test.svc/"
            meta = svc.class_metadata['Product']['Name']
            meta.name.should eq 'Name'
            meta.type.should eq 'Edm.String'
            meta.nullable.should eq true
            meta.fc_target_path.should eq "SyndicationTitle"
            meta.fc_keep_in_content.should eq false
          end
          it "should have the correct PropertyMetadata object for Description" do
            svc = OData::Service.new "http://test.com/test.svc/"
            meta = svc.class_metadata['Product']['Description']
            meta.name.should eq 'Description'
            meta.type.should eq 'Edm.String'
            meta.nullable.should eq true
            meta.fc_target_path.should eq "SyndicationSummary"
            meta.fc_keep_in_content.should eq false
          end
        end

        describe "single class" do
          it "should handle properties where a property is represented in the syndication title instead of the properties collection" do
            svc = OData::Service.new "http://test.com/test.svc/"
            svc.Products
            results = svc.execute
            results.first.Name.should eq "Bread"
          end
          it "should handle properties where a property is represented in the syndication summary instead of the properties collection" do
            svc = OData::Service.new "http://test.com/test.svc/"
            svc.Products
            results = svc.execute
            results.first.Description.should eq "Whole grain bread"
          end
        end

        describe "expanded inline class" do
          it "should handle properties where a property is represented in the syndication title instead of the properties collection" do
            svc = OData::Service.new "http://test.com/test.svc/"
            svc.Categories
            results = svc.execute

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
          svc = OData::Service.new "http://test.com/test.svc/"
          svc.Categories
          results = svc.execute
          food = results[0]

          food.Products.should be_an Array
        end

        it "should not make an array if the navigation property name is singular" do
          svc = OData::Service.new "http://test.com/test.svc/"
          svc.Products
          results = svc.execute
          product = results.first
          product.Category.should_not be_an Array
        end
      end

      describe "navigation properties" do
        it "should fill in PropertyMetadata for navigation properties" do
          svc = OData::Service.new "http://test.com/test.svc/"
          svc.class_metadata['Product'].should have_key 'Category'
        end
      end
    end

    describe "single layer inheritance" do
      before(:each) do
        # Metadata
        stub_request(:get, "http://test.com/test.svc/$metadata").
          with(:headers => DEFAULT_HEADERS).
          to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/inheritance/edmx_pluralsight.xml", __FILE__)), :headers => {})

        # Content - Courses
        stub_request(:get, /http:\/\/test\.com\/test\.svc\/Courses(?:.*)/).
          with(:headers => DEFAULT_HEADERS).
          to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/inheritance/result_pluralsight_courses.xml", __FILE__)), :headers => {})
      end

      it "should build all inherited attributes" do
        OData::Service.new "http://test.com/test.svc/"
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
        OData::Service.new "http://test.com/test.svc/"
        defined?(ModelItemBase).should eq nil
      end

      it "should fill inherited properties" do
        svc = OData::Service.new "http://test.com/test.svc/"
        svc.Courses
        courses = svc.execute
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
          to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/partial/partial_feed_metadata.xml", __FILE__)), :headers => {})

        # Content - Partial
        stub_request(:get, "http://test.com/test.svc/Partials").
          with(:headers => DEFAULT_HEADERS).
          to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/partial/partial_feed_part_1.xml", __FILE__)), :headers => {})

        stub_request(:get, "http://test.com/test.svc/Partials?$skiptoken='ERNSH'").
          with(:headers => DEFAULT_HEADERS).
          to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/partial/partial_feed_part_2.xml", __FILE__)), :headers => {})

        stub_request(:get, "http://test.com/test.svc/Partials?$skiptoken='ERNSH2'").
          with(:headers => DEFAULT_HEADERS).
          to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/partial/partial_feed_part_3.xml", __FILE__)), :headers => {})

      end

      it "should return the whole collection by default" do
        svc = OData::Service.new "http://test.com/test.svc/"
        svc.Partials
        results = svc.execute
        results.count.should eq 3
      end

      it "should return only the partial when specified by options" do
        svc = OData::Service.new("http://test.com/test.svc/", :eager_partial => false)
        svc.Partials
        results = svc.execute
        results.count.should eq 1
        svc.should be_partial
        while svc.partial?
          results.concat svc.next
        end
        results.count.should eq 3
      end

      context "with additional_params" do
        before(:each) do
          stub_request(:get, "http://test.com/test.svc/$metadata?extra_param=value").
            with(:headers => DEFAULT_HEADERS).
            to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/partial/partial_feed_metadata.xml", __FILE__)), :headers => {})

          stub_request(:get, "http://test.com/test.svc/Partials?extra_param=value").
            with(:headers => DEFAULT_HEADERS).
            to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/partial/partial_feed_part_1.xml", __FILE__)), :headers => {})

          stub_request(:get, "http://test.com/test.svc/Partials?$skiptoken='ERNSH'&extra_param=value").
            with(:headers => DEFAULT_HEADERS).
            to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/partial/partial_feed_part_2.xml", __FILE__)), :headers => {})
        end

        it "should persist the additional parameters for the next call" do
          svc = OData::Service.new("http://test.com/test.svc/", :eager_partial => false, :additional_params => { :extra_param => 'value' })
          svc.Partials
          svc.execute
          svc.next

          a_request(:get, "http://test.com/test.svc/Partials?$skiptoken='ERNSH'&extra_param=value").should have_been_made
        end
      end
    end

    describe "link queries" do
      before(:each) do
        # Required for the build_classes method
        stub_request(:get, /http:\/\/test\.com\/test\.svc\/\$metadata(?:\?.+)?/).
          with(:headers => DEFAULT_HEADERS).
          to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/sample_service/edmx_categories_products.xml", __FILE__)), :headers => {})

        stub_request(:get, "http://test.com/test.svc/Categories(1)/$links/Products").
          with(:headers => DEFAULT_HEADERS).
          to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/links/result_links_query.xml", __FILE__)), :headers => {})
      end
      it "should be able to parse the results of a links query" do
        svc = OData::Service.new "http://test.com/test.svc/"
        svc.Categories(1).links('Products')
        results = svc.execute
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
          to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/nested_expands/edmx_northwind.xml", __FILE__)), :headers => {})

        stub_request(:get, "http://test.com/test.svc/Products?$expand=Category,Category/Products&$top=2").
          with(:headers => DEFAULT_HEADERS).
          to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/nested_expands/northwind_products_category_expands.xml", __FILE__)), :headers => {})
      end

      it "should successfully parse the results" do
        svc = OData::Service.new "http://test.com/test.svc", { :namespace => "NW" }
        svc.Products.expand('Category').expand('Category/Products').top(2)
        lambda { svc.execute }.should_not raise_exception
      end

      it "should successfully parse a Category as a Category" do
        svc = OData::Service.new "http://test.com/test.svc", { :namespace => "NW" }
        svc.Products.expand('Category').expand('Category/Products').top(2)
        products = svc.execute
        products.first.Category.should be_a_kind_of(NW::Category)
      end

      it "should successfully parse the Category properties" do
        svc = OData::Service.new "http://test.com/test.svc", { :namespace => "NW" }
        svc.Products.expand('Category').expand('Category/Products').top(2)
        products = svc.execute
        products.first.Category.CategoryID.should eq 1
      end

      it "should successfully parse the Category children Products" do
        svc = OData::Service.new "http://test.com/test.svc", { :namespace => "NW" }
        svc.Products.expand('Category').expand('Category/Products').top(2)
        products = svc.execute
        products.first.Category.Products.length.should eq 12
      end

      it "should successfully parse the Category's child Product properties" do
        svc = OData::Service.new "http://test.com/test.svc", { :namespace => "NW" }
        svc.Products.expand('Category').expand('Category/Products').top(2)
        products = svc.execute
        products.first.Category.Products.first.ProductName.should eq "Chai"
      end
    end

    describe "handling of custom select queries" do

      context "when results are found" do
        before(:each) do
          stub_request(:get, "http://test.com/test.svc/$metadata").
            with(:headers => DEFAULT_HEADERS).
            to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/sample_service/edmx_categories_products.xml", __FILE__)), :headers => {})

          stub_request(:get, "http://test.com/test.svc/Products?$select=Name,Price").
            with(:headers => DEFAULT_HEADERS).
            to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/sample_service/result_select_products_name_price.xml", __FILE__)), :headers => {})
        end

        subject do
          svc = OData::Service.new "http://test.com/test.svc/"
          svc.Products.select "Name", "Price"
          svc.execute
        end

        it { should be_an Array }
        it { should_not be_empty }
        its(:first) { should be_a Product }
      end

      context "when there isn't a property by the name specified" do
        before(:each) do
          stub_request(:get, "http://test.com/test.svc/$metadata").
            with(:headers => DEFAULT_HEADERS).
            to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/sample_service/edmx_categories_products.xml", __FILE__)), :headers => {})

          stub_request(:get, "http://test.com/test.svc/Categories?$select=Price").
            with(:headers => DEFAULT_HEADERS).
            to_return(:status => 400, :body => File.new(File.expand_path("../fixtures/sample_service/result_select_categories_no_property.xml", __FILE__)), :headers => {})
        end

        it "raises an exception" do
          svc = OData::Service.new "http://test.com/test.svc/"
          svc.Categories.select "Price"
          expect { svc.execute }.to raise_error(OData::ServiceError) { |error|
            error.http_code.should eq 400
            error.message.should eq "Type 'RubyODataService.Category' does not have a property named 'Price' or there is no type with 'Price' name."
          }
        end
      end

      context "when a property requires $expand to traverse" do
        before(:each) do
          stub_request(:get, "http://test.com/test.svc/$metadata").
            with(:headers => DEFAULT_HEADERS).
            to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/sample_service/edmx_categories_products.xml", __FILE__)), :headers => {})

          stub_request(:get, "http://test.com/test.svc/Categories?$select=Name,Products/Name").
            with(:headers => DEFAULT_HEADERS).
            to_return(:status => 400, :body => File.new(File.expand_path("../fixtures/sample_service/result_select_categories_travsing_no_expand.xml", __FILE__)), :headers => {})

          stub_request(:get, "http://test.com/test.svc/Categories?$select=Name,Products/Name&$expand=Products").
            with(:headers => DEFAULT_HEADERS).
            to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/sample_service/result_select_categories_expand.xml", __FILE__)), :headers => {})
        end

        it "doesn't error" do
          svc = OData::Service.new "http://test.com/test.svc/"
          svc.Categories.select "Name", "Products/Name"
          expect { svc.execute }.to_not raise_error
        end

        it "returns the classes with the properties filled in" do
          svc = OData::Service.new "http://test.com/test.svc/"
          svc.Categories.select "Name", "Products/Name"
          results = svc.execute
          category = results.first
          category.Name.should eq "Category 0001"
          product = category.Products.first
          product.Name.should eq "Widget 0001"
        end
      end
    end
  end

  describe_private OData::Service do
    describe "parse value" do
      before(:each) do
        # Required for the build_classes method
        stub_request(:get, "http://test.com/test.svc/$metadata").
          with(:headers => DEFAULT_HEADERS).
          to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/edmx_empty.xml", __FILE__)), :headers => {})
      end

      it "should not error on an 'out of range' date" do
        # This date was returned in the Netflix OData service and failed with an ArgumentError: out of range using 1.8.7 (2010-12-23 patchlevel 330) [i386-mingw32]
        svc = OData::Service.new "http://test.com/test.svc/"
        element_to_parse = Nokogiri::XML.parse('<d:AvailableFrom m:type="Edm.DateTime">2100-01-01T00:00:00</d:AvailableFrom>').elements[0]
        lambda { svc.parse_value_xml(element_to_parse) }.should_not raise_exception
      end
    end
  end
end
