require 'spec_helper'

module OData
  describe ClassBuilder do
    describe "#initialize" do
      before(:each) do
        @methods = []
        @nav_props = []
        @svc = nil
        @namespace = nil
      end
      it "handles lowercase entities" do        
        klass = ClassBuilder.new 'product', @methods, @nav_props, @svc, @namespace
        result = klass.build
        result.should eq Product
      end
      it "should take in an instance of the service" do
        klass = ClassBuilder.new 'product', @methods, @nav_props, @svc, @namespace
      end
    end
  end
end