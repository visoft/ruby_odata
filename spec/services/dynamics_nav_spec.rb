require 'spec_helper'

module OData
  describe Service do

    describe "handling of Microsoft Dynamics Nav OData WebService" do

      before(:each) do
        # Required for the build_classes method
        username = "blabla"
        password = ""
        auth_string = "#{username}:#{password}"
        authorization_header = { authorization: "Basic #{Base64::encode64(auth_string).strip}" }
        headers = DEFAULT_HEADERS.merge(authorization_header)

        stub_request(:get, "http://test.com/nav.svc/$metadata").
          with(:headers => headers).
          to_return(:status => 200, :body => File.new( FIXTURES + "/ms_dynamics_nav/edmx_ms_dynamics_nav.xml"), :headers => {})

        stub_request(:get, "http://test.com/nav.svc/Customer").
          with(:headers => headers).
          to_return(:status => 200, :body => File.new( FIXTURES + "/ms_dynamics_nav/result_customer.xml"), :headers => {})

        stub_request(:get, "http://test.com/nav.svc/Customer('100013')").
          with(:headers => headers).
          to_return(:status => 200, :body => File.new( FIXTURES + "/ms_dynamics_nav/result_customer.xml"), :headers => {})

        stub_request(:get, "http://test.com/nav.svc/Customer(100013)").
          with(:headers => headers).
          to_return(:status => 400, :body => File.new( FIXTURES + "/ms_dynamics_nav/result_customer_error.xml"), :headers => {})

        stub_request(:get, "http://test.com/nav.svc/SalesOrder(Document_Type='Order',No='AB-1600013')").
          with(:headers => headers).
          to_return(:status => 200, :body => File.new( FIXTURES + "/ms_dynamics_nav/result_sales_order.xml"), :headers => {})

        @service = OData::Service.new "http://test.com/nav.svc/", { :username => username, :password => password, :verify_ssl => false }

      end

      after(:each) do
        remove_classes @service
      end

      it "should successfully parse null valued string properties" do
        @service.Customer
        results = @service.execute
        results.first.should be_a_kind_of(Customer)
      end

      it "should successfully return a customer by its string id" do
        @service.Customer('100013')
        results = @service.execute
        results.first.should be_a_kind_of(Customer)
        results.first.Name.should eq 'Contoso AG'
      end

      it "should cast to string if a customer is accessed with integer id" do
        @service.Customer(100013)
        results = @service.execute
        results.first.should be_a_kind_of(Customer)
        results.first.Name.should eq 'Contoso AG'
      end

      it "should successfully return a sales_order by its composite string ids" do
        @service.SalesOrder(Document_Type: 'Order', No: 'AB-1600013')
        results = @service.execute
        results.first.should be_a_kind_of(SalesOrder)
        results.first.No.should eq 'AB-1600013'
      end

    end
  end
end