require 'pickle/world'
require File.expand_path('../../../lib/ruby_odata', __FILE__)

module OData

  module PickleAdapter
    include Pickle::Adapter::Base
    
    @@service = OData::Service.new "http://#{WEBSERVER}:#{HTTP_PORT_NUMBER}/SampleService/Entities.svc"
    
    # Do not consider these to be part of the class list
    def self.except_classes
      @@except_classes ||= []
    end
    
    # Gets a list of the available models for this adapter
    def self.model_classes
      @@service.classes.values
    end
    
    # get a list of column names for a given class
    def self.column_names(klass)
      klass.properties.keys
    end

    # Get an instance by id of the model
    def self.get_model(klass, id)
      collection = klass.to_s.split('::').last.pluralize
      @@service.send collection, id
      @@service.execute.first
    end

    # Find the first instance matching conditions
    def self.find_first_model(klass, conditions)
      collection = klass.to_s.split('::').last.pluralize
      q = @@service.send collection
      q.filter(conditions)
      q.take(1)
      @@service.execute.first
    end

    # Find all models matching conditions
    def self.find_all_models(klass, conditions)
      collection = klass.to_s.split('::').last.pluralize
      q = @@service.send collection
      q.filter(conditions)
      @@service.execute
    end

    # Create a model using attributes
    def self.create_model(klass, attributes)
      instance = klass.send :make, attributes

      collection = klass.to_s.split('::').last.pluralize
      @@service.send "AddTo#{collection}", instance
      @@service.save_changes.first
    end
    
  end
end