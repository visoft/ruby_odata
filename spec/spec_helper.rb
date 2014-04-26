require 'ruby_odata'
require 'webmock/rspec'
require 'simplecov'
# require 'coveralls'
# Coveralls.wear_merged!

Dir[File.expand_path('../support/**/*.rb', __FILE__)].each { |f| require f }

DEFAULT_HEADERS = {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate'}

