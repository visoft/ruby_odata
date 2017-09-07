require 'spec_helper'
require 'base64'

module OData
    describe "handling of Microsoft System Center 2012" do
      let(:username) { "blabla" }
      let(:password) { "" }

      before(:each) do
        auth_string = "#{username}:#{password}"
        authorization_header = { authorization: "Basic #{Base64::encode64(auth_string).strip}" }
        headers = DEFAULT_HEADERS.merge(authorization_header)

        # Required for the build_classes method
        stub_request(:get, "http://test.com/test.svc/$metadata").
          with(:headers => headers).
          to_return(:status => 200, :body => File.new( FIXTURES + "/ms_system_center/edmx_ms_system_center.xml"), :headers => {})

        stub_request(:get, "http://test.com/test.svc/VirtualMachines").
          with(:headers => headers).
          to_return(:status => 200, :body => File.new( FIXTURES + "/ms_system_center/virtual_machines.xml"), :headers => {})

        stub_request(:get, "http://test.com/test.svc/HardwareProfiles?$filter=Memory%20eq%203500").
          with(:headers => headers).
          to_return(:status => 200, :body => File.new( FIXTURES + "/ms_system_center/hardware_profiles.xml"), :headers => {})

        stub_request(:get, "http://test.com/test.svc/VMTemplates").
          with(:headers => headers).
          to_return(:status => 200, :body => File.new( FIXTURES + "/ms_system_center/vm_templates.xml"), :headers => {})

        @service = OData::Service.new "http://test.com/test.svc/", { :username => username, :password => password, :verify_ssl => false, :namespace => "VMM" }
      end

      after(:all) do
        remove_classes @service
      end

      it "should successfully parse null valued string properties" do
        @service.VirtualMachines
        results = @service.execute
        results.first.should be_a_kind_of(VMM::VirtualMachine)
        results.first.CostCenter.should be_nil
      end

      it "should successfully return a virtual machine" do
        @service.VirtualMachines
        results = @service.execute
        results.first.should be_a_kind_of(VMM::VirtualMachine)
      end

      it "should successfully return a hardware profile for results that include a collection of complex types" do
        @service.HardwareProfiles.filter("Memory eq 3500")
        results = @service.execute
        results.first.should be_a_kind_of(VMM::HardwareProfile)
      end

      it "should successfully return a collection of complex types" do
        @service.HardwareProfiles.filter("Memory eq 3500")
        results = @service.execute
        granted_list = results.first.GrantedToList
        granted_list.should be_a_kind_of(Array)
        granted_list.first.should be_a_kind_of(VMM::UserAndRole)
        granted_list.first.RoleName.should == "Important Tenant"
      end


      it "should successfully return results that include a collection of Edm types" do
        @service.VMTemplates
        results = @service.execute
        results.first.should be_a_kind_of(VMM::VMTemplate)
      end

      it "should successfully return a collection of Edm types" do
        @service.VMTemplates
        results = @service.execute
        boot_order = results.first.BootOrder
        boot_order.should be_a_kind_of(Array)
        boot_order.first.should be_a_kind_of(String)
        boot_order.should eq ['CD', 'IdeHardDrive', 'PxeBoot', 'Floppy']
      end
    end
end
