require 'spec_helper'
require 'base64'

module OData
  describe "Keys" do
    describe "Collection with an int64 key Named 'id'" do

      before(:all) do
        stub_request(:get, "http://test.com/test.svc/$metadata").
          with(:headers => DEFAULT_HEADERS).
          to_return(:status => 200, :body => File.new( FIXTURES + "/int64_ids/edmx_car_service.xml"), :headers => {})
        @service = OData::Service.new "http://test.com/test.svc/"
      end

      after(:all) do
        remove_classes @service
      end

      context "has the correct metadata" do
        before(:all) do
          @id_meta = @service.class_metadata['Car']['id']
        end

        subject { @id_meta }

        its(:name)                { should eq('id') }
        its(:type)                { should eq('Edm.Int64') }
        its(:nullable)            { should eq false }
        its(:fc_target_path)      { should be_nil }
        its(:fc_keep_in_content)  { should be_nil }
      end

      context "can parse Id correctly" do
        before(:each) do
          stub_request(:get, "http://test.com/test.svc/Cars(213L)").
            with(:headers => DEFAULT_HEADERS).
            to_return(:status => 200, :body => File.new( FIXTURES + "/int64_ids/result_cars.xml"), :headers => {})

          @service.Cars(213)
          results = @service.execute
          @car = results.first
        end

        subject { @car }

        its(:id)      { should eq(213) }
        its(:color)   { should eq('peach') }
      end
    end

    describe "Collection with an int64 key named 'KeyId'" do

      before(:all) do
        stub_request(:get, "http://test.com/test.svc/$metadata").
          with(:headers => DEFAULT_HEADERS).
          to_return(:status => 200, :body => File.new( FIXTURES + "/int64_ids/edmx_boat_service.xml"), :headers => {})
        @service = OData::Service.new "http://test.com/test.svc/"
      end

      after(:all) do
        remove_classes @service
      end

      context "has the correct metadata" do
        before(:all) do
          @id_meta = @service.class_metadata['Boat']['KeyId']
        end

        subject { @id_meta }

        its(:name)                { should eq('KeyId') }
        its(:type)                { should eq('Edm.Int64') }
        its(:nullable)            { should eq(false) }
        its(:fc_target_path)      { should be_nil }
        its(:fc_keep_in_content)  { should be_nil }
      end

      context "can parse Id correctly" do
        before(:each) do
          stub_request(:get, "http://test.com/test.svc/Boats(213L)").
            with(:headers => DEFAULT_HEADERS).
            to_return(:status => 200, :body => File.new( FIXTURES + "/int64_ids/result_boats.xml"), :headers => {})

          @service.Boats(213)
          results = @service.execute
          @boat = results.first
        end

        subject { @boat }

        its(:id)      { should eq(213) }
        its(:color)   { should eq('blue') }
      end
    end

    describe "Collection with a string key named 'xxx" do
    end
    
  end

end
