lib =  File.dirname(__FILE__)
$: << lib + '/odata_ruby/'

require 'rubygems'
require 'active_support' 									# Used for serializtion to JSON
require 'active_support/inflector'
require 'cgi'
require 'open-uri'
require 'rest_client'
require 'nokogiri'

require lib + '/odata_ruby/query_builder'
require lib + '/odata_ruby/class_builder'
require lib + '/odata_ruby/operation'
require lib + '/odata_ruby/service'