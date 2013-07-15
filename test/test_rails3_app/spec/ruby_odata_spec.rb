require "spec_helper"

describe "ruby_odata" do
  before(:each) do
    stub_request(:get, "http://test.com/test.svc/$metadata?partnerid=123").
    with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate'}).
    to_return(:status => 200, :body => File.new(File.expand_path("../../../../spec/fixtures/rails_problem/metadata.xml", __FILE__)), :headers => {})

    stub_request(:get, "http://test.com/test.svc/CodeMapping?$filter=InstallationId%20eq%20guid'496a520d-18b9-4cbe-943f'&partnerid=123").
    with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate'}).
    to_return(:status => 200, :body => File.new(File.expand_path("../../../../spec/fixtures/rails_problem/code_mappings.xml", __FILE__)), :headers => {})
  end
  it "should successfully query codemappings" do
    clinic_id = '496a520d-18b9-4cbe-943f'
    svc = OData::Service.new("http://test.com/test.svc", {additional_params: {partnerid: 123}})
    svc.CodeMapping.filter("InstallationId eq guid'#{clinic_id}'")
    lambda { svc.execute }.should_not raise_exception
  end
  it "should successfully query codemappings" do
    clinic_id = '496a520d-18b9-4cbe-943f'
    svc = OData::Service.new("http://test.com/test.svc", {additional_params: {partnerid: 123}})
    svc.CodeMapping.filter("InstallationId eq guid'#{clinic_id}'")
    mappings = svc.execute
    mapping = mappings.first
    mapping.Id.should eq 894
  end
end