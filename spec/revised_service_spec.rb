require 'spec_helper'

module OData
  describe Service do
    before(:all) do
      stub_request(:get, /http:\/\/test\.com\/test\.svc\/\$metadata(?:\?.+)?/).
      with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate'}).
      to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/sample_service/edmx_categories_products.xml", __FILE__)), :headers => {})

      @cat_prod_service = OData::Service.new "http://test.com/test.svc"
    end
    subject { @cat_prod_service }
    
    context "methods" do
      it { should respond_to :update_object }
      it { should respond_to :delete_object }
      it { should respond_to :save_changes }
      it { should respond_to :load_property }
      it { should respond_to :add_link }
      it { should respond_to :execute }
      it { should respond_to :partial? }
      it { should respond_to :next }
      it { should respond_to :classes }
      it { should respond_to :class_metadata }
      it { should respond_to :collections }
      it { should respond_to :options }
      it { should respond_to :function_imports }
    
      context "after parsing metadata" do
        it { should respond_to :Products }
        it { should respond_to :Categories }
        it { should respond_to :AddToProducts }
        it { should respond_to :AddToCategories }
      end
    end
    context "collections method" do
      subject { @cat_prod_service.collections }
      it { should include 'Products' }
      it { should include 'Categories' }
      it "should expose the edmx type of objects" do
        subject['Products'][:edmx_type].should eq 'RubyODataService.Product'
        subject['Categories'][:edmx_type].should eq 'RubyODataService.Category'
      end
      it "should expose the local model type" do
        subject['Products'][:type].should eq Product
        subject['Categories'][:type].should eq Category                
      end
    end
    context "class metadata" do
      subject { @cat_prod_service.class_metadata }
      it { should_not be_empty}
      it { should have_key 'Product' }
      it { should have_key 'Category' }
      context "should have keys for each property" do
        subject { @cat_prod_service.class_metadata['Category'] }
        it { should have_key 'Id' }
        it { should have_key 'Name' }
        it { should have_key 'Products' }
        it "should return a PropertyMetadata object for each property" do
          subject['Id'].should be_a PropertyMetadata
          subject['Name'].should be_a PropertyMetadata
          subject['Products'].should be_a PropertyMetadata
        end
        it "should have correct PropertyMetadata for Category.Id" do
          meta = subject['Id']
          meta.name.should eq 'Id'
          meta.type.should eq 'Edm.Int32'
          meta.nullable.should eq false
          meta.fc_target_path.should be_nil
          meta.fc_keep_in_content.should be_nil
          meta.nav_prop.should eq false
        end
        it "should have correct PropertyMetadata for Category.Name" do
          meta = subject['Name']
          meta.name.should eq 'Name'
          meta.type.should eq 'Edm.String'
          meta.nullable.should eq false
          meta.fc_target_path.should be_nil
          meta.fc_keep_in_content.should be_nil
          meta.nav_prop.should eq false
        end
        it "should have correct PropertyMetadata for Category.Products" do
          meta = subject['Products']
          meta.name.should eq 'Products'
          meta.type.should be_nil
          meta.nullable.should eq true
          meta.fc_target_path.should be_nil
          meta.fc_keep_in_content.should be_nil
          meta.nav_prop.should eq true
          meta.association.should_not be_nil
        end
      end
    end
    context "function_imports method" do
      subject { @cat_prod_service.function_imports }
      it { should_not be_empty}
      it { should have_key 'CleanDatabaseForTesting' }
      it { should have_key 'EntityCategoryWebGet' }
      it { should have_key 'EntitySingleCategoryWebGet' }
      it "should expose the http method" do
        subject['CleanDatabaseForTesting'][:http_method].should eq 'POST'
        subject['EntityCategoryWebGet'][:http_method].should eq 'GET'
        subject['EntitySingleCategoryWebGet'][:http_method].should eq 'GET'
      end
      it "should expose the return type" do
        subject['CleanDatabaseForTesting'][:return_typo].should be_nil
        subject['EntityCategoryWebGet'][:return_type].should eq Array
        subject['EntityCategoryWebGet'][:inner_return_type].should eq Category
        subject['EntitySingleCategoryWebGet'][:return_type].should eq Category
        subject['EntitySingleCategoryWebGet'][:inner_return_type].should be_nil
        subject['CategoryNames'][:return_type].should eq Array
        subject['CategoryNames'][:inner_return_type].should eq String
      end
      it "should provide a hash of parameters" do
        subject['EntityCategoryWebGet'][:parameters].should be_nil
        subject['EntitySingleCategoryWebGet'][:parameters].should be_a Hash
        subject['EntitySingleCategoryWebGet'][:parameters]['id'].should eq 'Edm.Int32'
      end     
      context "after parsing function imports" do
        subject { @cat_prod_service }
        it { should respond_to :CleanDatabaseForTesting }
        it { should respond_to :EntityCategoryWebGet }
        it { should respond_to :EntitySingleCategoryWebGet }
        it { should respond_to :CategoryNames }
      end
      context "error checking" do
        subject { @cat_prod_service }
        it "should throw an exception if a parameter is passed in to a method that doesn't require one" do
          lambda { subject.EntityCategoryWebGet(1) }.should raise_error(ArgumentError, "wrong number of arguments (1 for 0)")
        end
        it "should throw and exception if more parameters are passed in than required by the function" do
          lambda { subject.EntitySingleCategoryWebGet(1,2) }.should raise_error(ArgumentError, "wrong number of arguments (2 for 1)")
        end
      end
      context "url and http method checks" do
        subject { @cat_prod_service }
        before { stub_request(:any, /http:\/\/test\.com\/test\.svc\/(.*)/) }
        it "should call the correct url with the correct http method for a post with no parameters" do
          subject.CleanDatabaseForTesting
          a_request(:post, "http://test.com/test.svc/CleanDatabaseForTesting").should have_been_made
        end
        it "should call the correct url with the correct http method for a get with no parameters" do
          subject.EntityCategoryWebGet
          a_request(:get, "http://test.com/test.svc/EntityCategoryWebGet").should have_been_made
        end
        it "should call the correct url with the correct http method for a get with parameters" do
          subject.EntitySingleCategoryWebGet(1)
          a_request(:get, "http://test.com/test.svc/EntitySingleCategoryWebGet?id=1").should have_been_made
        end
      end
      context "function import result parsing" do
        subject { @cat_prod_service }
        before(:each) do
          stub_request(:post, "http://test.com/test.svc/CleanDatabaseForTesting").to_return(:status => 204)
          
          stub_request(:get, "http://test.com/test.svc/EntityCategoryWebGet").
          to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/sample_service/result_entity_category_web_get.xml", __FILE__)), :headers => {})
          
          stub_request(:get, "http://test.com/test.svc/EntitySingleCategoryWebGet?id=1").
          to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/sample_service/result_entity_single_category_web_get.xml", __FILE__)), :headers => {})

          stub_request(:get, "http://test.com/test.svc/CategoryNames").
          to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/sample_service/result_category_names.xml", __FILE__)), :headers => {})

          stub_request(:get, "http://test.com/test.svc/FirstCategoryId").
          to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/sample_service/result_first_category_id.xml", __FILE__)), :headers => {})
        end
        it "should return true if a function import post that returns successfully and doesn't have a return value (HTTP 204)" do
          result = subject.CleanDatabaseForTesting
          result.should be_true
        end
        it "should return a collection of entities for a collection" do
          result = subject.EntityCategoryWebGet
          result.should be_an Enumerable
          result.first.should be_a Category
          result.first.Name.should eq "Test Category"
        end
        it "should return a single entity if it isn't a collection" do
          result = subject.EntitySingleCategoryWebGet(1)
          result.should be_a Category
          result.Name.should eq "Test Category"
        end
        it "should return a collection of primitive types" do
          result = subject.CategoryNames
          result.should be_an Enumerable
          result.first.should be_a String
          result.first.should eq "Test Category 1"
        end
        it "should return a single primitive type" do
          result = subject.FirstCategoryId
          result.should be_a Fixnum
          result.should eq 1
        end
      end
    end
  end
  describe Service do
    it "should handle long keys properly" do
      stub_request(:get, "http://test.com/test.svc/$metadata").
      with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate'}).
      to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/edmx_service.xml", __FILE__)), :headers => {})
      
      svc = OData::Service.new "http://test.com/test.svc/"
      meta = svc.class_metadata['Car']['id']
      meta.name.should eq 'id'
      meta.type.should eq 'Edm.Int64'
      meta.nullable.should eq false
      meta.fc_target_path.should be_nil
      meta.fc_keep_in_content.should be_nil
    end
    
    it "should find record with proper id conversion and update it" do
      stub_request(:get, "http://test.com/test.svc/$metadata").
      with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate'}).
      to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/edmx_service.xml", __FILE__)), :headers => {})
      
      stub_request(:get, "http://test.com/test.svc/Cars(213L)").
      with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate', 'User-Agent'=>'Ruby'}).
      to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/edmx_service_cars.xml", __FILE__)), :headers => {})
      svc = OData::Service.new "http://test.com/test.svc/"
      
      svc.Cars(213)
      results = svc.execute
      results.size.should == 1
      car = results.first
      car.id.should eq 213
      car.color.should eq "peach"
      
      stub_request(:put, "http://test.com/test.svc/Cars(213L)").
      with(:body => "{\"__metadata\":{\"uri\":\"http://test.com/test.svc/Cars(213L)\"},\"id\":\"213\",\"color\":\"red\",\"num_spots\":null,\"striped\":null}",
          :headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate', 'Content-Length'=>'117', 'Content-Type'=>'application/json', 'User-Agent'=>'Ruby'}).
      to_return(:status => 204, :body => "", :headers => {})
               
      car.color = "red"
      svc.update_object(car)
      result = svc.save_changes
      result.should be_true
    end
  end
end