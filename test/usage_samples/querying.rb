#require 'ruby_odata'
require File.expand_path('../../../lib/ruby_odata', __FILE__)
require File.expand_path('../../../features/support/constants', __FILE__)

svc = OData::Service.new "http://#{WEBSERVER}:#{HTTP_PORT_NUMBER}/SampleService/RubyOData.svc"
ns_svc = OData::Service.new "http://#{WEBSERVER}:#{HTTP_PORT_NUMBER}/SampleService/RubyOData.svc", { :namespace => 'Models' }

puts "Querying for a list of data"
svc.Categories
categories = svc.execute
puts categories.to_json 

puts "\n\nQuerying for a single result #execute"
svc.Categories(1)
category = svc.execute.first # Note the use of first here since execute will always return an enumerable
puts category.to_json

puts "\nAn easier way to do the same thing #Category.first(1)"
category = Category.first(1)
puts category.to_json

puts "\n\nLazy Loading/Eager Loading"
puts "\nWithout expanding the query"
svc.Products(1)
prod1 = svc.execute.first
puts "#{prod1.to_json}\n"
puts "\nLazy Loading"
svc.load_property(prod1, "Category")
puts "#{prod1.to_json}\n"

puts "\nWith expanding the query (Eager Loading)"
svc.Products(1).expand('Category')
prod1 = svc.execute.first
puts "#{prod1.to_json}\n"

puts "\n\nNamespaced Entities (using the namespace Models)"
puts "\nUsing the standard service to pull the first product"
svc.Products(1)
prod1 = svc.execute.first
puts "The class return type from the standard service: #{prod1.class}"

puts "\nUsing the namespaced service to pull the first product"
ns_svc.Products(1)
prod2 = ns_svc.execute.first
puts "The class return type: #{prod2.class}\n"
