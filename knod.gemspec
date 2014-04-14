#coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |gem|
  gem.name          = 'knod'
  gem.version       = '0.3.1'
  gem.date          = '2014-04-12'
  gem.authors       = ['Ryan Moser']
  gem.email         = 'ryanpmoser@gmail.com'
  gem.homepage      = 'https://github.com/moserrya/knod'
  gem.summary       = 'A tiny RESTful http server'
  gem.description   = 'An http server built using Ruby\'s standard library'
  gem.license       = 'MIT'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}) { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_development_dependency "rake", '~> 10'
end
