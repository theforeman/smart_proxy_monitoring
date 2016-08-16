require 'test/unit'
require 'mocha/setup'
require 'json'
require 'ostruct'
require 'webmock/test_unit'
require 'mocha/test_unit'
require 'rack/test'

require 'smart_proxy_for_testing'

# create log directory in our (not smart-proxy) directory
FileUtils.mkdir_p File.dirname(Proxy::SETTINGS.log_file)
