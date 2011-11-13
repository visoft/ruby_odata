require 'ruby_odata'
require File.expand_path('../../../features/support/constants', __FILE__)

svc = OData::Service.new "http://#{WEBSERVER}:#{HTTP_PORT_NUMBER}/SampleService/Entities.svc"

puts "Querying for a list of data"
svc.Categories
categories = svc.execute
puts categories.to_json 

puts "\n\nQuerying for a single result"
svc.Categories(1)
category = svc.execute.first # Note the use of first here since execute will always return an enumerable
puts category.to_json

puts "\n\nLazy Loading/Eager Loading"
puts "\nWithout expanding the query"
svc.Products(1)
prod1 = svc.execute.first
puts "#{prod1.to_json}\n"

puts "\nWith expanding the query"
svc.Products(1).expand('Category')
prod1 = svc.execute.first
puts "#{prod1.to_json}\n"
