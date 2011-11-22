require 'spec_helper'

module OData
  describe Association do
    before(:all) do
      stub_request(:get, /http:\/\/test\.com\/test\.svc\/\$metadata(?:\?.+)?/).
      with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate'}).
      to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/sample_service/edmx_categories_products.xml", __FILE__)), :headers => {})

      @svc = OData::Service.new "http://test.com/test.svc/$metadata"
      @product_category = RSpecSupport::ElementHelpers.string_to_element('<NavigationProperty Name="Category" Relationship="Model.CategoryProduct" FromRole="Product" ToRole="Category"/>')
    end
    describe "#initialize singlular navigation property" do
      before { @association = Association.new @product_category, @svc.edmx }
      subject { @association }
      
      it "should set the association name" do
        subject.name.should eq 'CategoryProduct'
      end
      it "should set the association namespace" do
        subject.namespace.should eq 'Model'
      end
      it "should set the relationship name" do
        subject.relationship.should eq 'Model.CategoryProduct'
      end
      context "from_role method" do
        subject { @association.from_role }
        it { should have_key 'Product'}        
        it "should set the edmx type" do
          subject['Product'][:edmx_type].should eq 'Model.Product'
        end
        it "should set the multiplicity" do
          subject['Product'][:multiplicity].should eq '*'
        end
      end
      context "to_role method" do
        subject { @association.to_role }
        it { should have_key 'Category'}        
        it "should set the edmx type" do
          subject['Category'][:edmx_type].should eq 'Model.Category'
        end
        it "should set the multiplicity" do
          subject['Category'][:multiplicity].should eq '1'
        end
      end
    end
  end
end