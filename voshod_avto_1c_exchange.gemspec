# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'voshod_avto_1c_exchange/version'

Gem::Specification.new do |spec|

  spec.name          = "voshod_avto_1c_exchange"
  spec.version       = VoshodAvtoExchange::VERSION
  spec.authors       = ["Ivan Piliaiev"]
  spec.email         = ["piliaiev@gmail.com"]
  spec.description   = %q{Exchange 1C for v-avto.ru}
  spec.summary       = %q{Exchange 1C for v-avto.ru}
  spec.homepage      = "https://github.com/dancingbytes/voshod_avto_1c_exchange"
  spec.license       = "BSD"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.0.0'

  spec.add_dependency "nokogiri", '~> 1.6'

end
