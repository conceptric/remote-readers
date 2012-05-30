# -*- encoding: utf-8 -*-
require File.expand_path('../lib/remote-xml-reader/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["James Whinfrey"]
  gem.email         = ["james@conceptric.co.uk"]
  gem.description   = %q{A library of readers that take remote data streams and parse them to a format for application consumption}
  gem.summary       = %q{Remote stream parsing to a hash}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "remote-xml-reader"
  gem.require_paths = ["lib"]
  gem.version       = Remote::Xml::Reader::VERSION
  
  gem.add_development_dependency('rspec')
  gem.add_dependency('rake')  
  gem.add_dependency('nokogiri')    
end
