require 'spec_helper'

module OData
  describe ClassBuilder do
    describe "#initialize" do
      it "handles lowercase entities" do        
        klass = ClassBuilder.new 'product', [], []
        result = klass.build
        result.should == Product
      end
    end
  end
end