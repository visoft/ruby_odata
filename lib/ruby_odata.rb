lib =  File.dirname(__FILE__)
$: << lib + '/ruby_odata/'

require 'rubygems'
require 'active_support' 									# Used for serializtion to JSON
require 'active_support/inflector'
require 'cgi'
require 'open-uri'
require 'rest_client'
require 'nokogiri'

require lib + '/ruby_odata/query_builder'
require lib + '/ruby_odata/class_builder'
require lib + '/ruby_odata/operation'
require lib + '/ruby_odata/service'