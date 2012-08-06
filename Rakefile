require 'rdoc/task'
require 'bundler'
require 'rspec/core/rake_task'
require 'cucumber/rake/task'

RDoc::Task.new do |rd|
  rd.main = "README.rdoc"
  rd.rdoc_files.include("README.rdoc", "CHANGELOG.rdoc", "lib/**/*.rb")
  rd.rdoc_dir = 'doc'
end

desc "Run specs"
RSpec::Core::RakeTask.new do |t|
  t.pattern = "./spec/**/*_spec.rb" # don't need this, it's default.
  # Put spec opts in a file named .rspec in root
end

desc "Run features"
Cucumber::Rake::Task.new(:features) do |t|
  t.cucumber_opts = "features --format progress"
end


Bundler::GemHelper.install_tasks
task :default => [:spec, :features]