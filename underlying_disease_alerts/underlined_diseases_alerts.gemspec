# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'underlined_diseases_alerts/version'

Gem::Specification.new do |spec|
  spec.name          = "underlined_diseases_alerts"
  spec.version       = UnderlinedDiseasesAlerts::VERSION
  spec.authors       = ["abamboed"]
  spec.email         = ["abamboed@gmail.com"]

  spec.summary       = "Displaying underlined diseases alerts on patients dashboard"
  spec.description   = "Displaying underlined diseases alerts on patients dashboard"
  spec.homepage      = "https://eidsr.slack.com"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
#  spec.add_development_dependency "mysql", "2.9.1", "0.4.4"
#  spec.add_development_dependency "mysql2"
end
