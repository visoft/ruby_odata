require 'spec_helper'

module OData
  describe Association do

    before(:all) do
      stub_request(:get, /http:\/\/test\.com\/test\.svc\/\$metadata(?:\?.+)?/).
      with(:headers => DEFAULT_HEADERS).
      to_return(:status => 200, :body => File.new( FIXTURES + "/sample_service/edmx_categories_products.xml"), :headers => {})

      @service = OData::Service.new "http://test.com/test.svc/$metadata"
      @product_category = RSpecSupport::ElementHelpers.string_to_element('<NavigationProperty Name="Category" Relationship="RubyODataService.Category_Products" ToRole="Category_Products_Source" FromRole="Category_Products_Target"/>')
    end

    after(:all) do
      remove_classes @service
    end

    describe "#initialize singular navigation property" do
      before { @association = Association.new @product_category, @service.edmx }
      subject { @association }

      it "sets the association name" do
        subject.name.should eq 'Category_Products'
      end

      it "sets the association namespace" do
        subject.namespace.should eq 'RubyODataService'
      end

      it "sets the relationship name" do
        subject.relationship.should eq 'RubyODataService.Category_Products'
      end

      context "from_role method" do
        subject { @association.from_role }
        it { should have_key 'Category_Products_Target'}
        it "sets the edmx type" do
          subject['Category_Products_Target'][:edmx_type].should eq 'RubyODataService.Product'
        end
        it "sets the multiplicity" do
          subject['Category_Products_Target'][:multiplicity].should eq '*'
        end
      end

      context "to_role method" do
        subject { @association.to_role }
        it { should have_key 'Category_Products_Source'}
        it "sets the edmx type" do
          subject['Category_Products_Source'][:edmx_type].should eq 'RubyODataService.Category'
        end
        it "sets the multiplicity" do
          subject['Category_Products_Source'][:multiplicity].should eq '1'
        end
      end
    end
  end
end
