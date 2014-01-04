# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'PBManager/version'

Gem::Specification.new do |spec|
  spec.name          = "PBManager"
  spec.version       = PBManager::VERSION
  spec.authors       = ["Jack Lavender"]
  spec.email         = ["jack@lavnet.net"]
  spec.description   = %q{Bootstrap VM}
  spec.summary       = %q{Puppet Bootstrap Manager}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]


  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"

  # These are the dependencies from the initial project
  #spec.add_development_dependency "uri"
  #spec.add_development_dependency "net/http"
  #spec.add_development_dependency "net/https"
  spec.add_development_dependency "gpgme"

  # These are my standard "irb" fare,  not sure which ones will creep into the final product
  spec.add_development_dependency 'looksee'
  spec.add_development_dependency 'awesome_print'
  spec.add_development_dependency 'alchemist'
  spec.add_development_dependency 'wirble'


  # I don't know if I want to do this, just yet
  # spec.add_runtime_dependency 'rails', '~>4.0.0'
  # #pec.add_runtime_dependency 'mysql2'


end
