# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fleetctl/version'

Gem::Specification.new do |spec|
  spec.name          = 'fleetctl'
  spec.version       = Fleetctl::VERSION
  spec.authors       = ['Josh Lauer']
  spec.email         = ['jlauer@cloudspace.com']
  spec.summary       = %q{A simple wrapper for fleetctl}
  spec.description   = %q{Allows controlling fleet clusters via a ruby API}
  spec.homepage      = 'https://github.com/cloudspace/ruby-fleetctl'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake', '~> 10.3'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'simplecov', '~> 0.9.0'
  spec.add_dependency 'hashie', '~> 2'
  spec.add_dependency 'net-ssh', '= 2.9.1'
  spec.add_dependency 'net-scp', '= 1.2.1'
end
