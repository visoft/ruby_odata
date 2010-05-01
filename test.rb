require 'lib/odata_ruby'
svc = OData::Service.new "http://localhost:2301/Services/Entities.svc"
puts svc.plans


#puts svc.get_collections