Before do
  VCR.use_cassette("clean_database_for_testing") do
    RestClient.post "http://#{WEBSERVER}:#{HTTP_PORT_NUMBER}/SampleService/RubyOData.svc/CleanDatabaseForTesting", {}
  end
end