# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "ruby_odata/version"

Gem::Specification.new do |s|
  s.name        = "ruby_odata"
  s.version     = OData::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Damien White"]
  s.email       = ["damien.white@visoftinc.com"]
  s.homepage    = %q{http://github.com/visoft/ruby_odata}
  s.summary     = %q{Ruby consumer of OData services.}
  s.description = %q{An OData Client Library for Ruby.  Use this to interact with OData services}
  s.license     = "MIT"

  s.rubyforge_project = "ruby-odata"

  s.required_ruby_version = '>= 1.9.3'

  s.add_dependency("addressable", ">= 2.3.4")
  s.add_dependency("i18n", ">= 0.7.0")
  s.add_dependency("activesupport", "~> 3.0.0")
  s.add_dependency("excon", "~> 0.45.3")
  s.add_dependency("faraday")
  s.add_dependency("faraday_middleware")
  s.add_dependency("nokogiri", ">= 1.4.2")

  s.add_development_dependency("rake", ">= 12.0.0")
  s.add_development_dependency("rspec", ">= 3.4.4")
  s.add_development_dependency("rspec-its", "~> 1.2.0")
  s.add_development_dependency("cucumber", "~> 2.0.0")
  s.add_development_dependency("pickle", "~> 0.5.1")
  s.add_development_dependency("machinist", "~> 2.0")
  s.add_development_dependency("webmock")
  s.add_development_dependency("guard", "~> 2.12.5")
  s.add_development_dependency("guard-rspec", "~> 4.5.0")
  s.add_development_dependency("guard-cucumber", "~> 1.6.0")
  s.add_development_dependency("vcr", "~> 2.9.3")
  s.add_development_dependency("simplecov", "~> 0.7.1")
  s.add_development_dependency("coveralls", "~> 0.6.7")
  s.add_development_dependency("pry")
  s.add_development_dependency("pry-nav")

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
