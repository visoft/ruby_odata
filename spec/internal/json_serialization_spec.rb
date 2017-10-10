require 'spec_helper'

module OData
	describe "JSON serialization of objects" do
	  let(:username) { "blabla" }
	  let(:password) { "" }

	  before(:each) do
	    # Required for the build_classes method
	    stub_request(:get, "http://test.com/test.svc/$metadata").
	      with(:headers => DEFAULT_HEADERS).
	      to_return(:status => 200, :body => Fixtures.load("/ms_system_center/edmx_ms_system_center.xml"), :headers => {})

	    stub_request(:get, "http://test.com/test.svc/VirtualMachines").
	      with(:headers => DEFAULT_HEADERS).
	      to_return(:status => 200, :body => Fixtures.load("/ms_system_center/virtual_machines.xml"), :headers => {})

	    @service = OData::Service.new "http://test.com/test.svc/", { :username => username, :password => password, :verify_ssl => false, :namespace => "VMM" }
	  end

	  subject do
	    @service.VirtualMachines
	    results = @service.execute
	    results.first.as_json
	  end

	  after(:each) do
			remove_classes @service
		end

	  it "Should quote Edm.Int64 properties" do
	    subject["PerfDiskBytesWrite"].should be_a(String)
	  end

	  it "Should output collections with metadata" do
	    subject["VMNetworkAssignments"].should be_a(Hash)
	    subject["VMNetworkAssignments"].should have_key("__metadata")
	    subject["VMNetworkAssignments"]["__metadata"].should be_a(Hash)
	    subject["VMNetworkAssignments"]["__metadata"].should have_key("type")
	    subject["VMNetworkAssignments"]["__metadata"]["type"].should eq("Collection(VMM.VMNetworkAssignment)")
	    subject["VMNetworkAssignments"].should have_key("results")
	    subject["VMNetworkAssignments"]["results"].should be_a(Array)
	    subject["VMNetworkAssignments"]["results"].should eq([])
	  end
	end	
end