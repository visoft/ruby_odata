require 'spec_helper'

module OData
  describe "sample service" do

    before(:each) do
      # Required for the build_classes method
      stub_request(:get, /http:\/\/test\.com\/test\.svc\/\$metadata(?:\?.+)?/).
        with(:headers => DEFAULT_HEADERS).
        to_return(:status => 200, :body => Fixtures.load("/sample_service/edmx_categories_products.xml"), :headers => {})

      stub_request(:get, /http:\/\/test\.com\/test\.svc\/Products\(\d\)/).
        with(:headers => DEFAULT_HEADERS).
        to_return(:status => 200, :body => Fixtures.load("/sample_service/result_single_product.xml"), :headers => {})

      stub_request(:get, /http:\/\/test\.com\/test\.svc\/Products\(\d{2,}\)/).
        with(:headers => DEFAULT_HEADERS).
        to_return(:status => 200, :body => Fixtures.load("/sample_service/result_single_product_not_found.xml"), :headers => {})

      stub_request(:get, "http://test.com/test.svc/Products(1)/Category").
        with(:headers => DEFAULT_HEADERS).
        to_return(:status => 200, :body => Fixtures.load("/sample_service/result_single_category.xml"), :headers => {})

      stub_request(:get, "http://test.com/test.svc/Categories(1)").
        with(:headers => DEFAULT_HEADERS).
        to_return(:status => 200, :body => Fixtures.load("/sample_service/result_single_category.xml"), :headers => {})

      stub_request(:get, "http://test.com/test.svc/Categories(1)/Products").
        with(:headers => DEFAULT_HEADERS).
        to_return(:status => 200, :body => Fixtures.load("/sample_service/result_multiple_category_products.xml"), :headers => {})

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
        expect(Product.properties['Category'].nav_prop).to eq true
      end

      it "should create objects that expose an id property" do
        svc = OData::Service.new "http://test.com/test.svc/"
        svc.Products(1)
        product = svc.execute.first
        expect(product).to respond_to :id
      end

      it "should extract the id from the metadata" do
        svc = OData::Service.new "http://test.com/test.svc/"
        svc.Products(1)
        product = svc.execute.first
        expect(product.id).to eq 1
      end

      describe "Class.first method" do
        it "should exist on the create server objects" do
          svc = OData::Service.new "http://test.com/test.svc/"
          expect(Product).to respond_to :first
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
        expect(defined?(VisoftInc::Sample::Models::Product).nil?).to eq false
        expect(defined?(VisoftInc::Sample::Models::Category).nil?).to eq false
      end

      it "should create models in the specified namespace if the option is set (using Ruby style namespaces with double colons)" do
        svc = OData::Service.new "http://test.com/test.svc/", { :namespace => 'VisoftInc::Sample::Models' }
        defined?(VisoftInc::Sample::Models::Product).nil?.should eq false
        defined?(VisoftInc::Sample::Models::Category).nil?.should eq false
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

        if RUBY_VERSION.start_with? '2.3'
          a_request(:post, "http://test.com/test.svc/Categories(1)/$links/Products").
            with(:body => '{"uri":"http://test.com/test.svc/Products(1)"}',
                :headers => DEFAULT_HEADERS.merge({'Content-Type' => 'application/json'})).should have_been_made
        else
          a_request(:post, "http://test.com/test.svc/Categories(1)/$links/Products").
            with(:body => '"{\"uri\":\"http://test.com/test.svc/Products(1)\"}"',
                :headers => DEFAULT_HEADERS.merge({'Content-Type' => 'application/json'})).should have_been_made
        end
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
          if RUBY_VERSION.start_with? '2.3'
            WebMock.should have_requested(:post, "http://test.com/test.svc/$batch").with { |request|
              request.body.include? "POST http://test.com/test.svc/Categories(1)/$links/Products HTTP/1.1"
              request.body.include? '{"uri":"http://test.com/test.svc/Products(1)"}'
            }
          else
            WebMock.should have_requested(:post, "http://test.com/test.svc/$batch").with { |request|
              request.body.include? "POST http://test.com/test.svc/Categories(1)/$links/Products HTTP/1.1"
              request.body.include? '{\"uri\":\"http://test.com/test.svc/Products(1)\"}'
            }
          end
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

      describe "serializes nested collections" do
        # Compy with oData Deep Insert capabilities
        # http://docs.oasis-open.org/odata/odata-json-format/v4.0/os/odata-json-format-v4.0-os.html#_Toc372793073

        before :each do
          category = Category.new
          category.Products = [Product.new(Name: "First"), Product.new(Name: "Last")]
          @json = JSON.parse(category.to_json(type: :add))
        end

        it "should have an array for the Products key" do
          @json["Products"].should be_a_kind_of Array
        end

        it "should have a hash for each product" do
          @json["Products"].each{|x| x.should be_a_kind_of Hash}
        end

        it "should have the same data we put into the products" do
          @json["Products"].first["Name"].should eq "First"
          @json["Products"].last["Name"].should eq "Last"
        end
      end
    end
  end	
end
