# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'octoshark/version'

Gem::Specification.new do |spec|
  spec.name          = "octoshark"
  spec.version       = Octoshark::VERSION
  spec.authors       = ["Dalibor Nasevic"]
  spec.email         = ["dalibor.nasevic@gmail.com"]
  spec.summary       = %q{Octoshark is an ActiveRecord connection manager}
  spec.description   = %q{Octoshark is a connection manager for switching between multiple ActiveRecord connections}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "activerecord", ">= 4.0"

  spec.add_development_dependency "bundler",  "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec",    "~> 3.0.0"
  spec.add_development_dependency "sqlite3",  "~> 1.3.0"
end
