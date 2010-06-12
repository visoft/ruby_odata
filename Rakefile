require 'rake/rdoctask'
Rake::RDocTask.new do |rd|
	rd.main = "README.rdoc"
	rd.rdoc_files.include("README.rdoc", "CHANGELOG.rdoc", "lib/**/*.rb")
	rd.rdoc_dir = 'doc'
end

begin
	require 'jeweler'
	Jeweler::Tasks.new do |gemspec|
		gemspec.name = "ruby_odata"
		gemspec.summary = "Ruby consumer of OData services."
		gemspec.description = "An OData Client Library for Ruby.  Use this to interact with OData services"
		gemspec.email = "damien.white@visoftinc.com"
		gemspec.homepage = "http://github.com/visoft/ruby_odata"
		gemspec.authors = ["Damien White"]
		gemspec.add_dependency('activesupport', '>= 2.3.5')
		gemspec.add_dependency('rest-client', '>= 1.5.1')
		gemspec.add_dependency('nokogiri', '>= 1.4.2')
		gemspec.rubyforge_project = 'ruby-odata'
	end
	Jeweler::GemcutterTasks.new
	Jeweler::RubyforgeTasks.new do |rubyforge|
    rubyforge.doc_task = "rdoc"
  end
rescue LoadError
	puts "Jeweler not available. Install it with: gem install jeweler"
end
