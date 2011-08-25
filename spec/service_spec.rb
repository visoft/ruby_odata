require 'spec_helper'

module OData
  describe Service do
    describe "#initialize" do
      it "truncates passed in end slash from uri when making the request" do      
        # Required for the build_classes method
        stub_request(:get, "http://test.com/test.svc/$metadata").
        with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate'}).
        to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/edmx_empty.xml", __FILE__)), :headers => {})
        
        svc = OData::Service.new "http://test.com/test.svc/"
      end
      it "doesn't error with lowercase entities" do
        # Required for the build_classes method
        stub_request(:get, "http://test.com/test.svc/$metadata").
        with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate'}).
        to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/edmx_lowercase.xml", __FILE__)), :headers => {})
        
        lambda { OData::Service.new "http://test.com/test.svc" }.should_not raise_error
      end
    end
    
    describe "lowercase collections" do
      before(:each) do
        # Required for the build_classes method
        stub_request(:get, "http://test.com/test.svc/$metadata").
        with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate'}).
        to_return(:status => 200, :body => File.new(File.expand_path("../fixtures/edmx_lowercase.xml", __FILE__)), :headers => {})
      end
      
      it "should respond_to a lowercase collection" do
        svc = OData::Service.new "http://test.com/test.svc"
        svc.respond_to?('acronyms').should be_true
      end
      
      it "should allow a lowercase collections to be queried" do
        svc = OData::Service.new "http://test.com/test.svc"
        lambda { svc.send('acronyms') }.should_not raise_error
      end
    end
  end
end