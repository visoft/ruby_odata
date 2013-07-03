require 'bundler'
require 'rspec/core/rake_task'
require 'cucumber/rake/task'

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

desc "Run with code coverage"
task :coverage do
  ENV['COVERAGE'] = 'true' if Gem::Version.new(RUBY_VERSION) > Gem::Version.new('1.9')

  Rake::Task["spec"].execute
  Rake::Task["features"].execute
end

desc "Run test with coveralls"
task :test_with_coveralls =>   [:coverage, 'coveralls_push_workaround']
task :coveralls_push_workaround do
  if Gem::Version.new(RUBY_VERSION) > Gem::Version.new('1.9')
    require 'coveralls/rake/task'
    Coveralls::RakeTask.new
    Rake::Task["coveralls:push"].invoke
  end
end