Before do
  Sham.reset
  RestClient.post "http://#{WEBSERVER}:#{HTTP_PORT_NUMBER}/SampleService/RubyOData.svc/CleanDatabaseForTesting", {}
end