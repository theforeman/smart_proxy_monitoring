require 'test_helper'
require 'smart_proxy_monitoring'

class MonitoringConfigTest < Test::Unit::TestCase
  def test_omitted_settings_have_default_values
    Proxy::Monitoring::Plugin.load_test_settings({})
    assert_equal 'monitoring_icinga2', Proxy::Monitoring::Plugin.settings.use_provider
  end
end
