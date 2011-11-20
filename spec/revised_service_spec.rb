require 'spec_helper'

module OData
  describe Service do
    before(:all) do
      stub_request(:get, /http:\/\/test\.com\/test\.svc\/\$metadata(?:\?.+)?/).
      with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate'}).
      to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/sample_service/edmx_categories_products.xml", __FILE__)), :headers => {})

      @cat_prod_service = OData::Service.new "http://test.com/test.svc/$metadata"
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
    
      context "after parsing metadata" do
        it { should respond_to :Products }
        it { should respond_to :Categories }
        it { should respond_to :AddToProducts }
        it { should respond_to :AddToCategories }
      end
    end
    context "collections method" do
      subject { @collections = @cat_prod_service.collections }
      it { should include 'Products' }
      it { should include 'Categories' }
      it "should expose the edmx type of objects" do
        subject['Products'][:edmx_type].should eq 'Model.Product'
        subject['Categories'][:edmx_type].should eq 'Model.Category'
      end
      it "should expose the local model type" do
        subject['Products'][:type].should eq Product
        subject['Categories'][:type].should eq Category                
      end
    end
  end
end