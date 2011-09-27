Before do
  Sham.reset
  RestClient.post "http://localhost:#{HTTP_PORT_NUMBER}/SampleService/Entities.svc/CleanDatabaseForTesting", {}
end