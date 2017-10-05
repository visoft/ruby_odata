require 'spec_helper'

module OData

    describe "handling of SAP results" do
      before(:each) do
        # Required for the build_classes method
        stub_request(:get, "http://test.com/test.svc/$metadata").
          with(:headers => DEFAULT_HEADERS).
          to_return(:status => 200, :body => Fixtures.load("/sap/edmx_sap_demo_flight.xml"), :headers => {})

        stub_request(:get, "http://test.com/test.svc/z_demo_flightCollection").
          with(:headers => DEFAULT_HEADERS).
          to_return(:status => 200, :body => Fixtures.load("/sap/result_sap_demo_flight_missing_category.xml"), :headers => {})
      end

      it "should handle entities without a category element" do
        svc = OData::Service.new "http://test.com/test.svc/"
        svc.z_demo_flightCollection
        results = svc.execute
        results.first.should be_a_kind_of(ZDemoFlight)
      end
    end

end