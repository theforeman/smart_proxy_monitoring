require 'test_helper'
require 'smart_proxy_monitoring'

class MonitoringIcingaDirectorConfigTest < Test::Unit::TestCase
  def test_default_configuration
    Proxy::Monitoring::IcingaDirector::Plugin.load_test_settings({})
    assert_nil Proxy::Monitoring::IcingaDirector::Plugin.settings.director_user
    assert_nil Proxy::Monitoring::IcingaDirector::Plugin.settings.director_password
    assert_equal true, Proxy::Monitoring::IcingaDirector::Plugin.settings.verify_ssl
  end
end
