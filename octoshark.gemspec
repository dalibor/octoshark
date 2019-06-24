# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'octoshark/version'

Gem::Specification.new do |spec|
  spec.name          = "octoshark"
  spec.version       = Octoshark::VERSION
  spec.authors       = ["Dalibor Nasevic"]
  spec.email         = ["dalibor.nasevic@gmail.com"]
  spec.summary       = %q{Octoshark is an ActiveRecord connection switcher}
  spec.description   = %q{Octoshark is a library for switching between multiple ActiveRecord connections}
  spec.homepage      = "https://github.com/dalibor/octoshark"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "activerecord", ">= 3.0"

  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec",    "~> 3.7.0"
  spec.add_development_dependency "sqlite3",  "~> 1.4.1"
  spec.add_development_dependency "mysql2",   "~> 0.5.2"
  spec.add_development_dependency "appraisal"
end
