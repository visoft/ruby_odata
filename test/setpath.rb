# Open template config file and write in current directory to virtual path
puts "Replacing %SAMPLE_SERVICE_DIR% with #{Dir.pwd}\\SampleService"
File.open("applicationhost.config", "w") {|file| file.puts File.read("applicationhost.config.template").gsub("%SAMPLE_SERVICE_DIR%", "#{Dir.pwd.gsub("\/", "\\")}\\SampleService" ) }
