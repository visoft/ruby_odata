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

  s.rubyforge_project = "ruby-odata"

  s.add_dependency('activesupport', '>= 2.3.5')
  s.add_dependency('rest-client', '>= 1.5.1')
  s.add_dependency('nokogiri', '>= 1.4.2')
  
  s.add_development_dependency('rspec', '~> 2.5.0')
  s.add_development_dependency('cucumber', '~> 0.10.2')
  s.add_development_dependency('faker', '~> 0.9.5')
  s.add_development_dependency('machinist', '~> 1.0.6')
  s.add_development_dependency('webmock', '~> 1.6.2')

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end