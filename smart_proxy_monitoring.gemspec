require File.expand_path('../lib/smart_proxy_monitoring/version', __FILE__)

Gem::Specification.new do |s|
  s.name = 'smart_proxy_monitoring'
  s.version = Proxy::Monitoring::VERSION

  s.summary = "Monitoring plug-in for Foreman's smart proxy"
  s.description = "Monitoring plug-in for Foreman's smart proxy"
  s.authors = ['Timo Goebel', 'Dirk Goetz']
  s.email = ['timo.goebel@dm.de', 'dirk.goetz@netways.de']
  s.extra_rdoc_files = ['README.md', 'LICENSE']
  s.files = Dir['{lib,settings.d,bundler.d}/**/*'] + s.extra_rdoc_files
  s.homepage = 'https://github.com/theforeman/smart_proxy_monitoring'
  s.license = 'GPL-3.0'
  s.add_dependency 'rest-client'
  s.add_dependency 'json'

  s.add_development_dependency('rake')
  s.add_development_dependency('mocha')
  s.add_development_dependency('test-unit')
end
