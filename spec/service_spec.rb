require 'spec_helper'

module OData
  describe Service do
    describe "#initialize" do
      it "truncates passed in end slash from uri when making the request" do
        # Required for the build_classes method
        stub_request(:get, "http://test.com/test.svc/$metadata").
        with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate'}).
        to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/edmx_empty.xml", __FILE__)), :headers => {})

        svc = OData::Service.new "http://test.com/test.svc/"
      end
      it "doesn't error with lowercase entities" do
        # Required for the build_classes method
        stub_request(:get, "http://test.com/test.svc/$metadata").
        with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate'}).
        to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/edmx_lowercase.xml", __FILE__)), :headers => {})

        lambda { OData::Service.new "http://test.com/test.svc" }.should_not raise_error
      end

      describe "additional query string parameters" do
        before(:each) do
          # Required for the build_classes method
          stub_request(:get, /http:\/\/test\.com\/test\.svc\/\$metadata(?:\?.+)?/).
          with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate'}).
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
          with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate'}).
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
        with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate'}).
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

    describe "lowercase collections" do
      before(:each) do
        # Required for the build_classes method
        stub_request(:get, "http://test.com/test.svc/$metadata").
        with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate'}).
        to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/edmx_lowercase.xml", __FILE__)), :headers => {})
      end

      it "should respond_to a lowercase collection" do
        svc = OData::Service.new "http://test.com/test.svc"
        svc.respond_to?('acronyms').should be_true
      end

      it "should allow a lowercase collections to be queried" do
        svc = OData::Service.new "http://test.com/test.svc"
        lambda { svc.send('acronyms') }.should_not raise_error
      end
    end

    describe "handling of SAP results" do
      before(:each) do
        # Required for the build_classes method
        stub_request(:get, "http://test.com/test.svc/$metadata").
        with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate'}).
        to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/sap/edmx_sap_demo_flight.xml", __FILE__)), :headers => {})

        stub_request(:get, "http://test.com/test.svc/z_demo_flightCollection").
        with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate'}).
        to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/sap/result_sap_demo_flight_missing_category.xml", __FILE__)), :headers => {})
      end

      it "should handle entities without a category element" do
        svc = OData::Service.new "http://test.com/test.svc/"
        svc.z_demo_flightCollection
        results = svc.execute
        results.first.should be_a_kind_of(ZDemoFlight)
      end
    end

    describe "collections, objects, metadata etc" do
      before(:each) do
        # Metadata
        stub_request(:get, "http://test.com/test.svc/$metadata").
        with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate'}).
        to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/feed_customization/edmx_feed_customization.xml", __FILE__)), :headers => {})

        # Content - Products
        stub_request(:get, /http:\/\/test\.com\/test\.svc\/Products(?:.*)/).
        with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate'}).
        to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/feed_customization/result_feed_customization_products_expand.xml", __FILE__)), :headers => {})

        # Content - Categories expanded Products
        stub_request(:get, /http:\/\/test\.com\/test\.svc\/Categories(?:.*)/).
        with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate'}).
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
        with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate'}).
        to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/inheritance/edmx_pluralsight.xml", __FILE__)), :headers => {})

        # Content - Courses
        stub_request(:get, /http:\/\/test\.com\/test\.svc\/Courses(?:.*)/).
        with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate'}).
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
        with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate'}).
        to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/partial/partial_feed_metadata.xml", __FILE__)), :headers => {})

        # Content - Partial
        stub_request(:get, "http://test.com/test.svc/Partials").
        with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate'}).
        to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/partial/partial_feed_part_1.xml", __FILE__)), :headers => {})

        stub_request(:get, "http://test.com/test.svc/Partials?$skiptoken='ERNSH'").
        with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate'}).
        to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/partial/partial_feed_part_2.xml", __FILE__)), :headers => {})

        stub_request(:get, "http://test.com/test.svc/Partials?$skiptoken='ERNSH2'").
        with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate'}).
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
         with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate', 'User-Agent'=>'Ruby'}).
         to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/partial/partial_feed_metadata.xml", __FILE__)), :headers => {})

          stub_request(:get, "http://test.com/test.svc/Partials?extra_param=value").
            with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate'}).
            to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/partial/partial_feed_part_1.xml", __FILE__)), :headers => {})

          stub_request(:get, "http://test.com/test.svc/Partials?$skiptoken='ERNSH'&extra_param=value").
            with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate'})
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
        with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate'}).
        to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/sample_service/edmx_categories_products.xml", __FILE__)), :headers => {})

        stub_request(:get, "http://test.com/test.svc/Categories(1)/$links/Products").
        with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate'}).
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

    describe "sample service" do
      before(:each) do
        # Required for the build_classes method
        stub_request(:get, /http:\/\/test\.com\/test\.svc\/\$metadata(?:\?.+)?/).
        with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate'}).
        to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/sample_service/edmx_categories_products.xml", __FILE__)), :headers => {})

        stub_request(:get, /http:\/\/test\.com\/test\.svc\/Products\(\d\)/).
        with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate'}).
        to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/sample_service/result_single_product.xml", __FILE__)), :headers => {})

        stub_request(:get, /http:\/\/test\.com\/test\.svc\/Products\(\d{2,}\)/).
        with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate'}).
        to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/sample_service/result_single_product_not_found.xml", __FILE__)), :headers => {})

        stub_request(:get, "http://test.com/test.svc/Products(1)/Category").
        with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate'}).
        to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/sample_service/result_single_category.xml", __FILE__)), :headers => {})

        stub_request(:get, "http://test.com/test.svc/Categories(1)").
        with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate'}).
        to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/sample_service/result_single_category.xml", __FILE__)), :headers => {})

        stub_request(:get, "http://test.com/test.svc/Categories(1)/Products").
        with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate'}).
        to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/sample_service/result_multiple_category_products.xml", __FILE__)), :headers => {})

        stub_request(:post, "http://test.com/test.svc/Categories(1)/$links/Products").to_return(:status => 204)
        stub_request(:post, "http://test.com/test.svc/$batch").to_return(:status => 202)
      end

      describe "lazy loading" do
        after(:each) do
          Object.send(:remove_const, 'Product') if Object.const_defined? 'Product'
          Object.send(:remove_const, 'Category') if Object.const_defined? 'Category'
        end

        it "should have a load property method" do
          svc = OData::Service.new "http://test.com/test.svc/"
          svc.should respond_to(:load_property)
        end

        it "should throw an exception if the object isn't tracked" do
          svc = OData::Service.new "http://test.com/test.svc/"
          new_object = Product.new
          lambda { svc.load_property(new_object, "Category") }.should raise_error(NotSupportedError, "You cannot load a property on an entity that isn't tracked")
        end

        it "should throw an exception if there isn't a method matching the navigation property passed in" do
          svc = OData::Service.new "http://test.com/test.svc/"
          svc.Products(1)
          product = svc.execute.first
          lambda { svc.load_property(product, "NoMatchingMethod") }.should raise_error(ArgumentError, "'NoMatchingMethod' is not a valid navigation property")
        end

        it "should throw an exception if the method passed in is a standard property (non-navigation)" do
          svc = OData::Service.new "http://test.com/test.svc/"
          svc.Products(1)
          product = svc.execute.first
          lambda { svc.load_property(product, "Name") }.should raise_error(ArgumentError, "'Name' is not a valid navigation property")
        end

        it "should fill a single navigation property" do
          svc = OData::Service.new "http://test.com/test.svc/"
          svc.Products(1)
          product = svc.execute.first
          svc.load_property(product, "Category")
          product.Category.should_not be_nil
          product.Category.Id.should eq 1
          product.Category.Name.should eq 'Category 1'
        end

        it "should fill a collection navigation property" do
          svc = OData::Service.new "http://test.com/test.svc/"
          svc.Categories(1)
          category = svc.execute.first
          svc.load_property(category, "Products")
          category.Products.first.should be_a Product
          category.Products[0].Id.should eq 1
          category.Products[1].Id.should eq 2
        end

        it "should not mutate the object's metadata" do
          svc = OData::Service.new "http://test.com/test.svc/"
          svc.Products(1)
          product = svc.execute.first
          original_metadata = product.__metadata.to_json
          svc.load_property(product, "Category")
          product.__metadata.to_json.should == original_metadata
        end
      end

      describe "find, create, add, update, and delete" do
        after(:each) do
          Object.send(:remove_const, 'Product') if Object.const_defined? 'Product'
          Object.send(:remove_const, 'Category') if Object.const_defined? 'Category'
        end

        it "should implement an AddTo method for collection" do
          svc = OData::Service.new "http://test.com/test.svc/"
          svc.should respond_to :AddToCategories
          svc.should respond_to :AddToProducts
        end

        it "should create objects with an initialize method that can build the object from a hash" do
          svc = OData::Service.new "http://test.com/test.svc/"
          product = Product.new 'Id' => 1000, 'Name' => 'New Product'
          product.Id.should eq 1000
          product.Name.should eq 'New Product'
        end

        it "should create objects that rejects keys that don't have corresponding methods" do
          svc = OData::Service.new "http://test.com/test.svc/"
          lambda { Product.new 'NotAProperty' => true }.should raise_error NoMethodError
        end

        it "should create objects that expose a properties class method that lists the properties for the object" do
          svc = OData::Service.new "http://test.com/test.svc/"
          Product.properties.should include 'Id'
          Product.properties.should include 'Name'
          Product.properties.should include 'Category'
        end

        it "should have full metadata for a property returned from the properties method" do
          svc = OData::Service.new "http://test.com/test.svc/"
          Product.properties['Category'].should be_a PropertyMetadata
          Product.properties['Category'].nav_prop.should be_true
        end

        it "should create objects that expose an id property" do
          svc = OData::Service.new "http://test.com/test.svc/"
          svc.Products(1)
          product = svc.execute.first
          product.should respond_to :id
        end

        it "should extract the id from the metadata" do
          svc = OData::Service.new "http://test.com/test.svc/"
          svc.Products(1)
          product = svc.execute.first
          product.id.should eq 1
        end

        describe "Class.first method" do
          it "should exist on the create server objects" do
            svc = OData::Service.new "http://test.com/test.svc/"
            Product.should respond_to :first
          end
          it "should return nil if an id isn't passed in" do
            svc = OData::Service.new "http://test.com/test.svc/"
            product = Product.first(nil)
            product.should be_nil
          end
          it "should return nil if an id isn't found" do
            svc = OData::Service.new "http://test.com/test.svc/"
            product = Product.first(1234567890)
            product.should be_nil
          end
          it "should return a product if an id is found" do
            svc = OData::Service.new "http://test.com/test.svc/"
            product = Product.first(1)
            product.should_not be_nil
          end
        end
      end

      describe "namespaces" do
        after(:each) do
          VisoftInc::Sample::Models.send(:remove_const, 'Product')        if VisoftInc::Sample::Models.const_defined? 'Product'
          VisoftInc::Sample::Models.send(:remove_const, 'Category')       if VisoftInc::Sample::Models.const_defined? 'Category'

          VisoftInc::Sample.send(:remove_const, 'Models')                 if VisoftInc::Sample.const_defined? 'Models'
          VisoftInc.send(:remove_const, 'Sample')                         if VisoftInc.const_defined? 'Sample'
          Object.send(:remove_const, 'VisoftInc')                         if Object.const_defined? 'VisoftInc'
        end

        it "should create models in the specified namespace if the option is set (using a .NET style namespace with dots)" do
          svc = OData::Service.new "http://test.com/test.svc/", { :namespace => 'VisoftInc.Sample.Models' }
          defined?(VisoftInc::Sample::Models::Product).nil?.should be_false, 'VisoftInc::Sample::Models::Product was expected to be defined, but was not'
          defined?(VisoftInc::Sample::Models::Category).nil?.should be_false, 'VisoftInc::Sample::Models::Category was expected to be defined, but was not'
        end

        it "should create models in the specified namespace if the option is set (using Ruby style namespaces with double colons)" do
          svc = OData::Service.new "http://test.com/test.svc/", { :namespace => 'VisoftInc::Sample::Models' }
          defined?(VisoftInc::Sample::Models::Product).nil?.should be_false, 'VisoftInc::Sample::Models::Product was expected to be defined, but was not'
          defined?(VisoftInc::Sample::Models::Category).nil?.should be_false, 'VisoftInc::Sample::Models::Category was expected to be defined, but was not'
        end

        it "should fill object defined in a namespace" do
          svc = OData::Service.new "http://test.com/test.svc/", { :namespace => 'VisoftInc::Sample::Models' }
          svc.Categories(1)
          categories = svc.execute
          categories.should_not be_nil
          category = categories.first
          category.Id.should eq 1
          category.Name.should eq 'Category 1'
        end

        it "should fill the class_metadata hash" do
          svc = OData::Service.new "http://test.com/test.svc/", { :namespace => 'VisoftInc::Sample::Models' }
          svc.class_metadata.should_not be_empty
        end

        it "should add a key (based on the name) for each property class_metadata hash" do
          svc = OData::Service.new "http://test.com/test.svc/", { :namespace => 'VisoftInc::Sample::Models' }
          svc.class_metadata['VisoftInc::Sample::Models::Product'].should have_key 'Id'
          svc.class_metadata['VisoftInc::Sample::Models::Product'].should have_key 'Name'
          svc.class_metadata['VisoftInc::Sample::Models::Product'].should have_key 'Description'
        end

        it "should lazy load objects defined in a namespace" do
          svc = OData::Service.new "http://test.com/test.svc/", { :namespace => 'VisoftInc::Sample::Models' }
          svc.Categories(1)
          category = svc.execute.first
          svc.load_property category, 'Products'
          category.Products.should_not be_nil
          category.Products.first.Id.should eq 1
          category.Products.first.Name.should eq 'Widget 1'
        end
      end

      describe "add_link method" do
        it "should exist as a method on the service" do
          svc = OData::Service.new "http://test.com/test.svc/"
          svc.should respond_to(:add_link)
        end

        it "shouldn't be allowed if a parent isn't tracked" do
          svc = OData::Service.new "http://test.com/test.svc/"
          category = Category.new :Name => 'New Category'
          property = nil # Not needed for this test
          product = nil # Not needed for this test
          lambda { svc.add_link(category, property, product) }.should raise_error(NotSupportedError, "You cannot add a link on an entity that isn't tracked (Category)")
        end

        it "shouldn't be allowed if a property isn't found on the parent" do
          svc = OData::Service.new "http://test.com/test.svc/"
          svc.Categories(1)
          category = svc.execute.first
          property = 'NotAProperty'
          product = nil # Not needed for this test
          lambda { svc.add_link(category, property, product) }.should raise_error(ArgumentError, "'NotAProperty' is not a valid navigation property for Category")
        end

        it "shouldn't be allowed if a property isn't a navigation property on the parent" do
          svc = OData::Service.new "http://test.com/test.svc/"
          svc.Categories(1)
          category = svc.execute.first
          property = 'Name'
          product = nil # Not needed for this test
          lambda { svc.add_link(category, property, product) }.should raise_error(ArgumentError, "'Name' is not a valid navigation property for Category")
        end

        it "shouldn't be allowed if a child isn't tracked" do
          svc = OData::Service.new "http://test.com/test.svc/"
          svc.Categories(1)
          category = svc.execute.first
          property = 'Products'
          product = Product.new :Name => 'Widget 1'
          lambda { svc.add_link(category, property, product) }.should raise_error(NotSupportedError, "You cannot add a link on a child entity that isn't tracked (Product)")
        end

        it "should perform a post against the correct URL with the correct body on a single_save" do
          svc = OData::Service.new "http://test.com/test.svc/"
          svc.Categories(1)
          category = svc.execute.first
          svc.Products(1)
          product = svc.execute.first
          property = 'Products'
          svc.add_link(category, property, product)
          svc.save_changes
          a_request(:post, "http://test.com/test.svc/Categories(1)/$links/Products").
            with(:body => { "uri" => "http://test.com/test.svc/Products(1)" },
                 :headers => {'Content-Type' => 'application/json'}).should have_been_made
        end

        it "should add the child to the parent's navigation property on a single_save" do
          svc = OData::Service.new "http://test.com/test.svc/"
          svc.Categories(1)
          category = svc.execute.first
          svc.Products(1)
          product = svc.execute.first
          property = 'Products'
          svc.add_link(category, property, product)
          svc.save_changes
          category.Products.should include product
        end

        it "should add the parent to the child's navigation property on a single_save" do
          svc = OData::Service.new "http://test.com/test.svc/"
          svc.Categories(1)
          category = svc.execute.first
          svc.Products(1)
          product = svc.execute.first
          property = 'Products'
          svc.add_link(category, property, product)
          svc.save_changes
          product.Category.should eq category
        end

        describe "batch_save" do
          before(:each) do
            @svc = OData::Service.new "http://test.com/test.svc/"
            @category = Category.first(1)
            @product = Product.first(1)
            new_category = Category.new
            @svc.AddToCategories(new_category)
            @svc.add_link(@category, 'Products', @product)
            @svc.save_changes
          end

          it "should perform a post with the correct URL and body on a batch_save" do
            WebMock.should have_requested(:post, "http://test.com/test.svc/$batch").with { |request|
              request.body.include? "POST http://test.com/test.svc/Categories(1)/$links/Products HTTP/1.1"
              request.body.include? '{"uri":"http://test.com/test.svc/Products(1)"}'
            }
          end
          context "child is a part of the parent's collection" do
            subject { @category.Products }
            it { should include @product }
          end
          context "parent object should be filled in on the child"  do
            subject { @product.Category }
            it { should eq @category }
          end
        end
      end
    end

    describe "restful options" do
      it "should allow " do
        
      end
    end
  end

  describe_private OData::Service do
    describe "parse value" do
      before(:each) do
        # Required for the build_classes method
        stub_request(:get, "http://test.com/test.svc/$metadata").
        with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate'}).
        to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/edmx_empty.xml", __FILE__)), :headers => {})
      end

      it "should not error on an 'out of range' date" do
        # This date was returned in the Netflix OData service and failed with an ArgumentError: out of range using 1.8.7 (2010-12-23 patchlevel 330) [i386-mingw32]
        svc = OData::Service.new "http://test.com/test.svc/"
        element_to_parse = Nokogiri::XML.parse('<d:AvailableFrom m:type="Edm.DateTime">2100-01-01T00:00:00</d:AvailableFrom>').elements[0]
        lambda { svc.parse_value(element_to_parse) }.should_not raise_exception
      end
    end
  end
end
