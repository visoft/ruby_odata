Before do
  Sham.reset
  RestClient.post "http://localhost:8888/SampleService/Entities.svc/CleanDatabaseForTesting", {}
end