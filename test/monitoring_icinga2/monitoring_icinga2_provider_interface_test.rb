require 'test_helper'
require 'smart_proxy_monitoring_common/monitoring_common'
require 'smart_proxy_monitoring_icinga2/monitoring_icinga2_main'

class MonitoringIcinga2ProviderInterfaceTest < Test::Unit::TestCase
  def test_provider_interface
    monitoring_server = ::Proxy::Monitoring::Icinga2::Provider.new
    assert monitoring_server.respond_to?(:set_downtime_host)
    assert monitoring_server.respond_to?(:remove_downtime_host)
    assert monitoring_server.respond_to?(:create_host)
    assert monitoring_server.respond_to?(:update_host)
    assert monitoring_server.respond_to?(:remove_host)
    assert monitoring_server.respond_to?(:query_host)
  end
end
