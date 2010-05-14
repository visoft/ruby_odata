lib =  File.dirname(__FILE__)
$: << lib + '/odata_ruby/'

require 'rubygems'
require 'active_support' # Used for serializtion to JSON

require lib + '/odata_ruby/query_builder'
require lib + '/odata_ruby/builder'
require lib + '/odata_ruby/operation'
require lib + '/odata_ruby/service'