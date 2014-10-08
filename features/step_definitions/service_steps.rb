STANDARD_URL = "http://#{WEBSERVER}:#{HTTP_PORT_NUMBER}/SampleService/RubyOData.svc"
BASICAUTH_URL = "http://#{WEBSERVER}:#{HTTP_PORT_NUMBER}/SampleService/BasicAuth/RubyOData.svc"
HTTPS_BASICAUTH_URL = "https://#{WEBSERVER}:#{HTTPS_PORT_NUMBER}/SampleService/BasicAuth/RubyOData.svc"

When /^(.*) first (last query )?result(\'s)?(.*)$/ do |pre, last_query, apos, post|
  the_step = "#{pre} #{last_query}result#{apos}#{post}"
  first_result
  step the_step
end

When /^(.*) first (last )?save result(.*)$/ do |pre, last, post|
  the_step = "#{pre} #{last}save result#{post}"
  first_save
  step the_step
end

Given /^a HTTP ODataService exists$/ do
  VCR.use_cassette("unsecured_metadata") do
    @service = OData::Service.new(STANDARD_URL)
  end
end

Given /^a HTTP BasicAuth ODataService exists using username "([^\"]*)" and password "([^\"]*)"$/ do |username, password|
  @service = OData::Service.new(BASICAUTH_URL, { :username => username, :password => password })
end

Given /^a HTTP BasicAuth ODataService exists using username "([^\"]*)" and password "([^\"]*)" it should throw an exception with message "([^\"]*)"$/ do |username, password, msg|
  lambda { @service = OData::Service.new(BASICAUTH_URL, { :username => username, :password => password }) }.should raise_error(msg)
end

Given /^a HTTP BasicAuth ODataService exists it should throw an exception with message "([^\"]*)"$/ do |msg|
  lambda { @service = OData::Service.new(BASICAUTH_URL) }.should raise_error(msg)
end

Given /^a HTTPS BasicAuth ODataService exists using self-signed certificate and username "([^\"]*)" and password "([^\"]*)"$/ do |username, password|
  @service = OData::Service.new(HTTPS_BASICAUTH_URL, { :username => username, :password => password, :verify_ssl => false })
end

When /^I call "([^\"]*)" on the service$/ do |method|
  @service_query = @service.send(method)
end

Then /^the integer result should be ([^\"]*)$/ do |result|
  @service_result.should eq result.to_i
end

Then /^I should be able to call "([^\"]*)" on the service$/ do |method|
  require 'pry'
  binding.pry

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
  @service_result.class.to_s.should eq type
end

Then /^the result should have a method: "([^\"]*)"$/ do |method|
  @service_result.respond_to?(method.to_sym).should eq true
end

Then /^the method "([^\"]*)" on the result should equal: "([^\"]*)"$/ do |method, value|
  @service_result.send(method.to_sym).to_s.should eq value
end

Then /^the method "([^\"]*)" on the result should be nil$/ do |method|
  @service_result.send(method.to_sym).should eq nil
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

When /^I ask for the count$/ do
  @service_query.count
end

When /^I ask for the links for "([^\"]*)"$/ do |nav_prop|
  @service_query.links(nav_prop)
end

Then /^the method "([^\"]*)" on the result should be of type "([^\"]*)"$/ do |method, type|
  result = @service_result.send(method.to_sym)
  result.class.to_s.should eq type
end

Given /^I call "([^\"]*)" on the service with a new "([^\"]*)" object(?: with (.*))?$/ do |method, object, fields|
  fields_hash = parse_fields_string(fields)

  obj = object.constantize.send(:make, fields_hash)
  @service.send(method.to_sym, obj)
end

When /^I save changes$/ do
  @saved_result = @service.save_changes
end

Then /^the save result should be of type "([^\"]*)"$/ do |type|
  @saved_result.class.to_s.should eq type
end

When /^I call "([^\"]*)" on the service with the last save result$/ do |method|
  @service.send(method.to_sym, @saved_result)
end

When /^I call "([^\"]*)" on the service with the last query result$/ do |method|
  @service.send(method.to_sym, @service_result)
end

Then /^the save result should equal: "([^\"]*)"$/ do |result|
  @saved_result.to_s.should eq result
end

Then /^the method "([^\"]*)" on the save result should equal: "([^\"]*)"$/ do |method, value|
  result = @saved_result.send(method.to_sym)
  result.should eq value
end

When /^blueprints exist for the service$/ do
  require File.expand_path(File.dirname(__FILE__) + "../../../test/blueprints")
end

Given /^I call "([^\"]*)" on the service with a new "([^\"]*)" object it should throw an exception with message "([^\"]*)"$/ do |method, object, msg|
  obj = object.constantize.send :make
  lambda { @service.send(method.to_sym, obj) }.should raise_error(msg)
end

When /^I save changes it should throw an exception with message containing "([^"]*)"$/ do |msg|
  lambda { @service.save_changes }.should raise_error(/#{msg}.*/)
end

Then /^no "([^\"]*)" should exist$/ do |collection|
  @service.send(collection)
  results = @service.execute
  results.should eq []
end

Then /^the primitive results should be:$/ do |table|
  # table is a Cucumber::Ast::Table
  values = table.hashes
  result_table = Cucumber::Ast::Table.new(values)
  table.diff!(result_table)
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

Then /^a class named "([^\"]*)" should exist$/ do |klass_name|
  (Object.const_defined? klass_name).should eq true
end

# Operations against a method on the service result
When /^I call "([^\"]*)" for "([^\"]*)" on the result$/ do |method2, method1|
  r1 = @service_result.send(method1)
  @operation_result = r1.send(method2)
end

Then /^the operation should not be null$/ do
  @operation_result.nil?.should eq false
end

Then /^the method "([^\"]*)" on the result's method "([^\"]*)" should equal: "([^\"]*)"$/ do |method, result_method, value|
  obj = @service_result.send(result_method.to_sym)
  obj.send(method.to_sym).to_s.should eq value
end

When /^I set "([^\"]*)" on the result's method "([^\"]*)" to "([^\"]*)"$/ do |property_name, result_method, value|
  @service_result.send(result_method).send("#{property_name}=", value)
end

# Type tests
Then /^the "([^\"]*)" method on the object should return a (.*)/ do |method_name, type|
  methods = method_name.split '.'
  if methods.length == 1
    @service_result.first.send(method_name).class.to_s.should eq type
  else
    @service_result.first.send(methods[0]).send(methods[1]).class.to_s.should eq type
  end
end

Then /^I store the last query result for comparison$/ do
  @stored_query_result = @service_result
end

Then /^the new query result's time "([^\"]*)" should equal the saved query result$/ do |method_name|
  methods = method_name.split '.'
  @service_result.send(methods[0]).send(methods[1]).xmlschema(3).should eq @stored_query_result.send(methods[0]).send(methods[1]).xmlschema(3)
end


Then /^the result count should be (\d+)$/ do |expected_count|
  @service_result.count.should eq expected_count.to_i
end

When /^I add a link between #{capture_model} and #{capture_model} on "([^"]*)"$/ do |parent, child, property|
  @service.add_link(created_model(parent), property, created_model(child))
end

Given /^I call the service method "([^"]*)"(?: with (.*))?$/ do |method, args|
  if args
    @service_result = @service.send(method, args)
  else
    @service_result = @service.send(method)
  end
end

When /^(.*) within a cassette named "([^"]*)"$/ do |the_step, cassette_name|
  VCR.use_cassette(cassette_name) { step the_step }
end
