require 'test_helper'
require 'smart_proxy_monitoring'

class MonitoringIcinga2ProviderTest < Test::Unit::TestCase
  def setup
    Proxy::Monitoring::Icinga2::Plugin.load_test_settings({})
    @provider = Proxy::Monitoring::Icinga2::Provider.new
  end

  def test_create_host
    icinga_result = '{"results":[{"code":200.0,"status":"Object was created"}]}'
    stub_request(:put, "https://localhost:5665/v1/objects/hosts/xyz.example.com").
      with(
        :body => "{\"templates\":[\"foreman-host\"],\"address\":\"1.1.1.1\",\"address6\":\"2001:db8::1\"}"
    ).
    to_return(:status => 200, :body => icinga_result)

    attributes = {
      'ip' => '1.1.1.1',
      'ip6' => '2001:db8::1',
    }
    @provider.create_host('xyz.example.com', attributes)
  end

  def test_update_host
    icinga_result = '{"results":[{"code":200.0,"name":"xyz.example.com","status":"Attributes updated.","type":"Host"}]}'
    stub_request(:post, "https://localhost:5665/v1/objects/hosts/xyz.example.com").
      with(
        :body => "{\"templates\":[\"foreman-host\"],\"address\":\"1.1.1.1\",\"address6\":\"2001:db8::1\"}"
    ).
    to_return(:status => 200, :body => icinga_result)

    attributes = {
      'ip' => '1.1.1.1',
      'ip6' => '2001:db8::1',
    }
    @provider.update_host('xyz.example.com', attributes)
  end

  def test_remove_host
    icinga_result = '{"results":[{"code":200.0,"name":"xyz.example.com","status":"Object was deleted.","type":"Host"}]}'
    stub_request(:delete, "https://localhost:5665/v1/objects/hosts/xyz.example.com?cascade=1").
      to_return(:status => 200, :body => icinga_result)

    @provider.remove_host('xyz.example.com')
  end

  def test_set_downtime_host
    icinga_result = '{"results":[{"code":200.0,"legacy_id":2.0,"name":"xyz.example.com!xyz.example.com-1491819090-1","status":"Successfully scheduled downtime \'xyz.example.com!xyz.example.com-1491819090-1\' for object \'xyz.example.com\'."}]}'
    stub_request(:post, "https://localhost:5665/v1/actions/schedule-downtime?filter=host.name==%22xyz.example.com%22&type=Host").
      with(:body => "{\"author\":\"Foreman\",\"comment\":\"Downtime by Foreman\",\"start_time\":\"1491819090\",\"end_time\":\"1491819095\",\"duration\":1000}").
      to_return(:status => 200, :body => icinga_result)
    @provider.set_downtime_host('xyz.example.com', 'Foreman', 'Downtime by Foreman', '1491819090', '1491819095')
  end

  def test_remove_downtime_host
    icinga_result = '{"results":[{"code":200.0,"status":"Successfully removed all downtimes for object \'xyz.example.com\'."}]}'
    stub_request(:post, "https://localhost:5665/v1/actions/remove-downtime?author==%22Foreman%22&comment=%22Downtime%20by%20Foreman%22&filter=host.name==%22xyz.example.com%22&type=Host").
      with(:body => "{}").
      to_return(:status => 200, :body => icinga_result)
    @provider.remove_downtime_host('xyz.example.com', 'Foreman', 'Downtime by Foreman')
  end
end
