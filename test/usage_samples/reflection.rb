require 'ruby_odata'
require File.expand_path('../../../features/support/constants', __FILE__)

svc = OData::Service.new "http://#{WEBSERVER}:#{HTTP_PORT_NUMBER}/SampleService/RubyOData.svc"

puts "Retrieving collections exposed by a service:"
puts svc.collections

puts "\nClasses created by the service"
puts svc.classes

puts "\nFunction Imports (custom service methods) found on the service"
puts svc.function_imports.to_json

puts "\nRetrieving the properties for the Product class"
puts Product.properties.to_json
