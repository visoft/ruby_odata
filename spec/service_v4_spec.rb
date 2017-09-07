require 'spec_helper'

module OData

  describe "V4 Service" do
    before(:all) do
      stub_request(:get, "http://test.com/test.svc/$metadata").
      with(:headers => DEFAULT_HEADERS).
      to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/v4/edmx_metadata.xml", __FILE__)), :headers => {})

      stub_request(:get, "http://test.com/test.svc/Categories").
      to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/v4/result_categories.xml", __FILE__)), :headers => {})

      @service = OData::Service.new "http://test.com/test.svc"
    end

    after(:all) do 
      remove_classes @service   
    end

    subject { @service }

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
      subject { @service.collections }
      it { should include 'Products' }
      it { should include 'Categories' }
      it "should expose the edmx type of objects" do
        subject['Products'][:edmx_type].should eq 'ODataDemo.Product'
        subject['Categories'][:edmx_type].should eq 'ODataDemo.Category'
      end
      it "should expose the local model type" do
        subject['Products'][:type].should eq Product
        subject['Categories'][:type].should eq Category
      end
    end

    context "class metadata" do
      subject { @service.class_metadata }
      it { should_not be_empty}
      it { should have_key 'Product' }
      it { should have_key 'Category' }

      context "should have keys for each property" do
        subject { @service.class_metadata['Category'] }
        it { should have_key 'ID' }
        it { should have_key 'Name' }
        it { should have_key 'Products' }
        it "should return a PropertyMetadata object for each property" do
          subject['ID'].should be_an OData::PropertyMetadata
          subject['Name'].should be_an OData::PropertyMetadata
          subject['Products'].should be_an OData::PropertyMetadata
        end
        it "should have correct PropertyMetadata for Category.Id" do
          meta = subject['ID']
          meta.name.should eq 'ID'
          meta.type.should eq 'Edm.Int32'
          meta.nullable.should eq false
          meta.fc_target_path.should be_nil
          meta.fc_keep_in_content.should be_nil
          meta.nav_prop.should eq false
          meta.is_key.should eq true
        end
        it "should have correct PropertyMetadata for Category.Name" do
          meta = subject['Name']
          meta.name.should eq 'Name'
          meta.type.should eq 'Edm.String'
          meta.nullable.should eq false
          meta.fc_target_path.should be_nil
          meta.fc_keep_in_content.should be_nil
          meta.nav_prop.should eq false
          meta.is_key.should eq false
        end
        it "should have correct PropertyMetadata for Category.Products" do
          meta = subject['Products']
          meta.name.should eq 'Products'
          meta.type.should eq 'Collection(ODataDemo.Product)'
          meta.nullable.should eq true
          meta.fc_target_path.should be_nil
          meta.fc_keep_in_content.should be_nil
          meta.nav_prop.should eq true
          meta.association.should_not be_nil
          meta.is_key.should eq false
        end
      end
    end
  end
end