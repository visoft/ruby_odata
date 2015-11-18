Before do
  VCR.use_cassette("clean_database_for_testing") do
    conn = Faraday.new(url: "http://#{WEBSERVER}:#{HTTP_PORT_NUMBER}")
    conn.post '/SampleService/RubyOData.svc/CleanDatabaseForTesting'
  end
end
