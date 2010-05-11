require 'lib/odata_ruby'

# http://odata.netflix.com/Catalog/People?$filter=Name eq 'James Cameron'&$expand=Awards,TitlesDirected
# http://odata.netflix.com/Catalog/People(13724)

@svc = OData::Service.new "http://odata.netflix.com/Catalog"
@svc.people(13724)
p = @svc.execute
puts p.name