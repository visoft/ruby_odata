require 'rubygems'
require 'rest_client'
require 'json'


puts RestClient.get 'http://127.0.0.1:2301/Services/Entities.svc/Plans', :accept => :json