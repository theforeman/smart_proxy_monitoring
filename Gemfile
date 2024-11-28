source 'https://rubygems.org'
gemspec

group :rubocop do
  gem 'rubocop', '~> 1.28.0'
  gem 'rubocop-performance'
  gem 'rubocop-rake'
end

group :test do
  gem 'mocha'
  gem 'public_suffix'
  gem 'rack-test'
  gem 'rake'
  gem 'smart_proxy', github: 'theforeman/smart-proxy', branch: ENV.fetch('SMART_PROXY_BRANCH', 'develop')
  gem 'test-unit', '~> 3'
  gem 'webmock'
end
