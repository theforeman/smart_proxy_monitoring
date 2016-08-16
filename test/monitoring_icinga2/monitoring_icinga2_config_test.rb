require 'test_helper'
require 'smart_proxy_monitoring'

class MonitoringIcinga2ConfigTest < Test::Unit::TestCase
  def test_default_configuration
    Proxy::Monitoring::Icinga2::Plugin.load_test_settings({})
    assert_equal 'localhost', Proxy::Monitoring::Icinga2::Plugin.settings.server
    assert_equal '5665', Proxy::Monitoring::Icinga2::Plugin.settings.api_port
    assert_equal true, Proxy::Monitoring::Icinga2::Plugin.settings.verify_ssl
  end
end
