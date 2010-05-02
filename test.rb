require 'lib/odata_ruby'
require 'json'
@svc = OData::Service.new "http://127.0.0.1:2301/Services/Entities.svc"
@svc.plans
plan = @svc.execute
puts plan.name