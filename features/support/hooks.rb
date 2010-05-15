Before do
	Sham.reset
	RestClient.post "http://127.0.0.1:2301/services/entities.svc/CleanDatabaseForTesting", {}
end