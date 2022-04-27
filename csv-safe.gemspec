lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'csv-safe'

Gem::Specification.new do |spec|
  spec.name          = 'csv-safe'
  spec.version       = '3.0.0'
  spec.authors       = ['Alex Zvorygin']
  spec.email         = ['grafetu@gmail.com']

  spec.summary       = 'Decorate ruby CSV library to sanitize ' \
    'output CSV against CSV injection attacks.'
  spec.homepage      = 'https://github.com/zvory/csv-safe'
  spec.license       = 'MIT'

  spec.files = Dir.glob('lib/**/*.rb')

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.6.0'

  spec.add_development_dependency 'bundler', '>= 2.1.4'
  spec.add_development_dependency "rake", ">= 12.3.3"
  spec.add_development_dependency 'rspec', '~> 3.0'
end
