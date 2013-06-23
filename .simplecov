if Gem::Version.new(RUBY_VERSION) > Gem::Version.new('1.9') && ENV['COVERAGE']
  require 'simplecov'
  require 'coveralls'

  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
    SimpleCov::Formatter::HTMLFormatter
  ]

  SimpleCov.start
end
