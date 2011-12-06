require File.expand_path('../../../lib/ruby_odata', __FILE__)
require File.expand_path('../../../features/support/constants', __FILE__)
require 'machinist/object'
require 'sham'
require 'faker'

svc = OData::Service.new "http://#{WEBSERVER}:#{HTTP_PORT_NUMBER}/SampleService/RubyOData.svc"
svc.CleanDatabaseForTesting #=> Comment this line out if you don't want to clear your test database

# This needs to be required after the service creates the entities
require File.expand_path('../../blueprints', __FILE__)

cat1 = Category.make
cat2 = Category.make
svc.AddToCategories(cat1)
svc.AddToCategories(cat2)

c1p1 = Product.make :Category => cat1
c1p2 = Product.make :Category => cat1
c2p1 = Product.make :Category => cat2
c2p2 = Product.make :Category => cat2
c2p3 = Product.make :Category => cat2

svc.AddToProducts(c1p1)
svc.AddToProducts(c1p2)
svc.AddToProducts(c2p1)
svc.AddToProducts(c2p2)
svc.AddToProducts(c2p3)

svc.save_changes