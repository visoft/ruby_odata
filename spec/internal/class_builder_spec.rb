require 'spec_helper'

module OData
  describe ClassBuilder do

    before(:each) do
      @methods = []
      @nav_props = []
      @svc = nil
      @namespace = nil
    end

    after(:each) do
      Object.send(:remove_const, 'Product')     if Object.const_defined? 'Product'
      Object.send(:remove_const, 'Namespace')   if Object.const_defined? 'Namespace'
    end

    context "Building the class" do
      subject { ClassBuilder.new('Product', @methods, @nav_props, @svc, @namespace).build }

      it "should take in an instance of the service" do
        subject.should eq Product
      end

      it "creates the :first class method" do
        expect(subject).to respond_to(:first)
      end

      it "creates :__metadata method" do
        expect(subject.new).to respond_to(:__metadata)
      end

      it "creates :as_json method" do
        expect(subject.new).to respond_to(:as_json)
      end
    end

    context "with additional params" do

      it "handles lowercase entities" do
        klass = ClassBuilder.new 'product', @methods, @nav_props, @svc, @namespace
        result = klass.build
        result.should eq Product
      end

      it "creates additional methods" do
        klass = ClassBuilder.new 'Product', [:method1], @nav_props, @svc, @namespace
        result = klass.build
        expect(result.new).to respond_to(:method1)
      end

      it "creates nav_props" do
        klass = ClassBuilder.new 'Product', @methods, [:navigate], @svc, @namespace
        result = klass.build
        expect(result.new).to respond_to(:navigate)
      end

      it "creates the class within a namespace" do
        klass = ClassBuilder.new 'Namespace::Product', @methods, @nav_props, @svc, "Namespace"
        result = klass.build
        expect(result).to eq Namespace::Product
      end

    end
  end
end