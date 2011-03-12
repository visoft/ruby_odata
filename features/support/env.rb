require 'lib/ruby_odata'
require 'machinist/object'
require 'sham'
require 'faker'

require 'ftools'
root_dir = File.expand_path(File.join(File.dirname(__FILE__), "../..", "test/SampleService/App_Data"))

if !File.exists?("#{root_dir}/TestDB.mdf")
  File.copy("#{root_dir}/_TestDB.mdf", "#{root_dir}/TestDB.mdf")
  File.copy("#{root_dir}/_TestDB_Log.ldf", "#{root_dir}/TestDB_Log.ldf")
end