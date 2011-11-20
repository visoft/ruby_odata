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
    def self.get_model(klass, id, expand = false)
      collection = klass.to_s.split('::').last.pluralize
      query = @@service.send collection, id

      if expand then
        # Expand all navigation properties
        navigation_properties = klass.properties.select { |k, v| v.nav_prop }
        # Ruby 1.9 Hash.select returns a Hash, 1.8 returns an Array, so normalize the return type
        props = (navigation_properties.is_a? Hash) ? navigation_properties : Hash[*navigation_properties.flatten]
        props.keys.each do |prop|
          query.expand(prop)
        end
      end

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

module Pickle
  module Session
    # return a newly selected model with the navigation properties expanded
    def model_with_associations(name)
      model = created_model(name)
      return nil unless model
      OData::PickleAdapter.get_model(model.class, model.id, true)
    end
  end
end