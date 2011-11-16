require 'ruby_odata'
require File.expand_path('../../../features/support/constants', __FILE__)

svc = OData::Service.new "http://#{WEBSERVER}:#{HTTP_PORT_NUMBER}/SampleService/Entities.svc"

puts "Retrieving collections exposed by a service:"
puts svc.collections

puts "\nClasses created by the service"
puts svc.classes

puts "\nRetrieving the properties for the Product class"
puts Product.properties