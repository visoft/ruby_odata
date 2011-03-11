Given /^an ODataService exists with uri: "([^\"]*)"$/ do |uri|
  @service = OData::Service.new(uri)
end

Given /^an ODataService exists with uri: "([^\"]*)" using username "([^\"]*)" and password "([^\"]*)"$/ do |uri, username, password|
  @service = OData::Service.new(uri, { :username => username, :password => password })
end

Given /^an ODataService exists with uri: "([^\"]*)" using username "([^\"]*)" and password "([^\"]*)" it should throw an exception with message "([^\"]*)"$/ do |uri, username, password, msg|  
  lambda { @service = OData::Service.new(uri, { :username => username, :password => password }) }.should raise_error(msg)
end

Given /^an ODataService exists with uri: "([^\"]*)" it should throw an exception with message "([^\"]*)"$/ do |uri, msg|  
  lambda { @service = OData::Service.new(uri) }.should raise_error(msg)
end

When /^I call "([^\"]*)" on the service$/ do |method|
  @service_query = @service.send(method)
end

Then /^the result should be "([^\"]*)"$/ do |result|
  @service_result.should == result 
end

Then /^I should be able to call "([^\"]*)" on the service$/ do |method|
  lambda { @service.send(method) }.should_not raise_error
end

Then /^I should not be able to call "([^\"]*)" on the service$/ do |method|
  lambda { @service.send(method) }.should raise_error
end

Then /^I should be able to call "([^\"]*)" on the service with args: "([^\"]*)"$/ do |method, args|
  lambda { @service.send(method, args) }.should_not raise_error
end

When /^I call "([^\"]*)" on the service with args: "([^\"]*)"$/ do |method, args|
  @service_query = @service.send(method, args)
end

When /^I run the query$/ do
  @service_result = @service.execute
end

Then /^the result should be of type "([^\"]*)"$/ do |type|
  @service_result.class.to_s.should == type
end

Then /^the result should have a method: "([^\"]*)"$/ do |method|
  @service_result.respond_to?(method.to_sym).should == true
end

Then /^the method "([^\"]*)" on the result should equal: "([^\"]*)"$/ do |method, value|
  @service_result.send(method.to_sym).to_s.should == value
end

Then /^the method "([^\"]*)" on the result should be nil$/ do |method|
  @service_result.send(method.to_sym).should == nil
end

When /^I set "([^\"]*)" on the result to "([^\"]*)"$/ do |property_name, value|
  @service_result.send("#{property_name}=", value)
end

Given /^I expand the query to include "([^\"]*)"$/ do |expands|
  @service_query.expand(expands)
end

When /^I filter the query with: "([^\"]*)"$/ do |filter|
  @service_query.filter(filter)
end

When /^I order by: "([^\"]*)"$/ do |order|
  @service_query.order_by(order)
end

When /^I skip (\d+)$/ do |skip|
  @service_query.skip(skip)
end

When /^I ask for the top (\d+)$/ do |top|
  @service_query.top(top)
end

Then /^the method "([^\"]*)" on the result should be of type "([^\"]*)"$/ do |method, type|
  result = @service_result.send(method.to_sym) 
  result.class.to_s.should == type
end

Given /^I call "([^\"]*)" on the service with a new "([^\"]*)" object(?: with (.*))?$/ do |method, object, fields|
  fields_hash = {}
  
  if !fields.nil?
    fields.split(', ').each do |field|
      if field =~ /^(?:(\w+): "(.*)")$/
        key = $1
        val = $2
        if val =~ /^@@LastSave$/
          val = @saved_result
        end
        
        fields_hash.merge!({ key => val })
      end
    end	
  end
  
  obj = object.constantize.send(:make, fields_hash)
  @service.send(method.to_sym, obj)
end

When /^I save changes$/ do
  @saved_result = @service.save_changes
end

Then /^the save result should be of type "([^\"]*)"$/ do |type|
  @saved_result.class.to_s.should == type
end

When /^I call "([^\"]*)" on the service with the last save result$/ do |method|
  @service.send(method.to_sym, @saved_result)
end

When /^I call "([^\"]*)" on the service with the last query result$/ do |method|
  @service.send(method.to_sym, @service_result)
end

Then /^the save result should equal: "([^\"]*)"$/ do |result|
  @saved_result.to_s.should == result
end

Then /^the method "([^\"]*)" on the save result should equal: "([^\"]*)"$/ do |method, value|
  result = @saved_result.send(method.to_sym)
  result.should == value
end

When /^blueprints exist for the service$/ do
  require File.expand_path(File.dirname(__FILE__) + "../../../test/blueprints")
end

Given /^I call "([^\"]*)" on the service with a new "([^\"]*)" object it should throw an exception with message "([^\"]*)"$/ do |method, object, msg|
  obj = object.constantize.send :make
  lambda { @service.send(method.to_sym, obj) }.should raise_error(msg)
end

Then /^no "([^\"]*)" should exist$/ do |collection|
  @service.send(collection)
  results = @service.execute
  results.should == []
end

Given /^the following (.*) exist:$/ do |plural_factory, table|
  # table is a Cucumber::Ast::Table
  factory = plural_factory.singularize
  table.hashes.map do |hash|
    obj = factory.constantize.send(:make, hash)
    @service.send("AddTo#{plural_factory}", obj)
    @service.save_changes
  end
end

Given /^(\d+) (.*) exist$/ do |num, plural_factory|
  factory = plural_factory.singularize
  num.to_i.times do 
    obj = factory.constantize.send(:make)
    @service.send("AddTo#{plural_factory}", obj)
  end
  @service.save_changes # Batch save
end

Then /^the result should be:$/ do |table|
  # table is a Cucumber::Ast::Table
  
  fields = table.hashes[0].keys
  
  # Build an array of hashes so that we can compare tables
  results = []
  
  @service_result.each do |result|
    obj_hash = Hash.new
    fields.each do |field|
      obj_hash[field] = result.send(field)
    end
    results << obj_hash
  end
  
  result_table = Cucumber::Ast::Table.new(results)
  
  table.diff!(result_table) 	
end

Then /^the save result should be:$/ do |table|
  # table is a Cucumber::Ast::Table
  
  fields = table.hashes[0].keys
  
  # Build an array of hashes so that we can compare tables
  results = []
  
  @saved_result.each do |result|
    obj_hash = Hash.new
    fields.each do |field|
      obj_hash[field] = result.send(field)
    end
    results << obj_hash
  end
  
  result_table = Cucumber::Ast::Table.new(results)
  
  table.diff!(result_table) 	
end

Then /^a class named "([^\"]*)" should exist$/ do |klass_name|
  (Object.const_defined? klass_name).should == true
end

# Operations against a method on the service result
When /^I call "([^\"]*)" for "([^\"]*)" on the result$/ do |method2, method1|
  r1 = @service_result.send(method1)
  @operation_result = r1.send(method2)
end

Then /^the operation should not be null$/ do
  @operation_result.nil?.should == false
end


Then /^the method "([^\"]*)" on the result's method "([^\"]*)" should equal: "([^\"]*)"$/ do |method, result_method, value|
  obj = @service_result.send(result_method.to_sym)
  obj.send(method.to_sym).to_s.should == value
end

When /^I set "([^\"]*)" on the result's method "([^\"]*)" to "([^\"]*)"$/ do |property_name, result_method, value|
  @service_result.send(result_method).send("#{property_name}=", value)
end

# Type tests
Then /^the "([^\"]*)" method should return a (.*)/ do |method_name, type|
  methods = method_name.split '.'
  if methods.length == 1
    @service_result.send(method_name).class.to_s.should == type
  else
    @service_result.send(methods[0]).send(methods[1]).class.to_s.should == type
  end

end
Then /^I store the last query result for comparison$/ do
  @stored_query_result = @service_result
end
Then /^the new query result's time "([^\"]*)" should equal the saved query result$/ do |method_name|
  methods = method_name.split '.'
  if methods.length == 1
    @service_result.send(method_name).xmlschema(3).should == @stored_query_result.send(method_name).xmlschema(3)
  else
    @service_result.send(methods[0]).send(methods[1]).xmlschema(3).should == @stored_query_result.send(methods[0]).send(methods[1]).xmlschema(3)
  end
end