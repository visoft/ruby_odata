require File.expand_path('../../features/support/constants', __FILE__)

# Open template config file and write in proper data
puts "Replacing Configuration Data"
File.open("applicationhost.config", "w") do |file|
  File.open("applicationhost.config.template", 'r').each do |line|
    line.gsub!("%SAMPLE_SERVICE_DIR%", "#{Dir.pwd.gsub("\/", "\\")}\\SampleService")
    line.gsub!("%HTTP_PORT_NUMBER%", "#{HTTP_PORT_NUMBER}")
    line.gsub!("%HTTPS_PORT_NUMBER%", "#{HTTPS_PORT_NUMBER}")
    line.gsub!("%WEBSERVER%", "#{WEBSERVER}")
    file.puts line
  end
end
