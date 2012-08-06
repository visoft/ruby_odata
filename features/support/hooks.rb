Before do
  RestClient.post "http://#{WEBSERVER}:#{HTTP_PORT_NUMBER}/SampleService/RubyOData.svc/CleanDatabaseForTesting", {}
end