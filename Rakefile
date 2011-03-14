require 'rake/rdoctask'
require 'bundler'

Rake::RDocTask.new do |rd|
  rd.main = "README.rdoc"
  rd.rdoc_files.include("README.rdoc", "CHANGELOG.rdoc", "lib/**/*.rb")
  rd.rdoc_dir = 'doc'
end

Bundler::GemHelper.install_tasks
