require 'spec_helper'

module OData
  describe Service do

    describe "handling of Microsoft Dynamics Nav OData WebService" do
      let(:username) { "blabla" }
      let(:password) { "" }

      before(:each) do
        auth_string = "#{username}:#{password}"
        authorization_header = { authorization: "Basic #{Base64::encode64(auth_string).strip}" }
        headers = DEFAULT_HEADERS.merge(authorization_header)

        # Required for the build_classes method
        stub_request(:get, "http://test.com/nav.svc/$metadata").
          with(:headers => headers).
          to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/ms_dynamics_nav/edmx_ms_dynamics_nav.xml", __FILE__)), :headers => {})

        stub_request(:get, "http://test.com/nav.svc/Customer").
          with(:headers => headers).
          to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/ms_dynamics_nav/result_customer.xml", __FILE__)), :headers => {})

        stub_request(:get, "http://test.com/nav.svc/Customer('100013')").
          with(:headers => headers).
          to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/ms_dynamics_nav/result_customer.xml", __FILE__)), :headers => {})

        stub_request(:get, "http://test.com/nav.svc/Customer(100013)").
          with(:headers => headers).
          to_return(:status => 400, :body => File.new(File.expand_path("../fixtures/ms_dynamics_nav/result_customer_error.xml", __FILE__)), :headers => {})

        stub_request(:get, "http://test.com/nav.svc/SalesOrder(Document_Type='Order',No='AB-1600013')").
          with(:headers => headers).
          to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/ms_dynamics_nav/result_sales_order.xml", __FILE__)), :headers => {})
      end

      after(:all) do
        Object.send(:remove_const, 'Customer')
        Object.send(:remove_const, 'SalesOrder')
      end

      it "should successfully parse null valued string properties" do        
        svc = OData::Service.new "http://test.com/nav.svc/", { :username => username, :password => password, :verify_ssl => false }
        svc.Customer
        results = svc.execute
        results.first.should be_a_kind_of(Customer)
      end

      it "should successfully return a customer by its string id" do
        svc = OData::Service.new "http://test.com/nav.svc/", { :username => username, :password => password, :verify_ssl => false }
        svc.Customer('100013')
        results = svc.execute
        results.first.should be_a_kind_of(Customer)
        results.first.Name.should eq 'Contoso AG'
      end

      it "should cast to string if a customer is accessed with integer id" do
        svc = OData::Service.new "http://test.com/nav.svc/", { :username => username, :password => password, :verify_ssl => false }
        svc.Customer(100013)
        results = svc.execute
        results.first.should be_a_kind_of(Customer)
        results.first.Name.should eq 'Contoso AG'
      end

      it "should successfully return a sales_order by its composite string ids" do
        svc = OData::Service.new "http://test.com/nav.svc/", { :username => username, :password => password, :verify_ssl => false }
        svc.SalesOrder(Document_Type: 'Order', No: 'AB-1600013')
        results = svc.execute
        results.first.should be_a_kind_of(SalesOrder)
        results.first.No.should eq 'AB-1600013'
      end

    end
  end
end