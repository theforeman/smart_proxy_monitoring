require 'test_helper'
require 'smart_proxy_monitoring'

class MonitoringIcinga2ProviderTest < Test::Unit::TestCase
  def setup
    Proxy::Monitoring::Icinga2::Plugin.load_test_settings({})
    @provider = Proxy::Monitoring::Icinga2::Provider.new
  end

  def test_query_host
    icinga_result = '{"results":[{"attrs":{"address":"1.1.1.1","address6":"2001:db8::1","templates":["xyz.example.com","foreman-host"],"vars":null},"joins":{},"meta":{},"name":"xyz.example.com","type":"Host"}]}'
    stub_request(:get, "https://localhost:5665/v1/objects/hosts/xyz.example.com?attrs=vars&attrs=address&attrs=address6&attrs=templates").
      to_return(:status => 200, :body => icinga_result)

    attributes = {
      'ip' => '1.1.1.1',
      'ip6' => '2001:db8::1',
    }
    data = @provider.query_host('xyz.example.com')

    assert_equal attributes, data
  end

  def test_query_host_non_existent
    icinga_result = '{"error":404.0,"status":"No objects found."}'
    stub_request(:get, "https://localhost:5665/v1/objects/hosts/xyz.example.com?attrs=vars&attrs=address&attrs=address6&attrs=templates").
      to_return(:status => 200, :body => icinga_result)

    assert_raises Proxy::Monitoring::NotFound do
      @provider.query_host('xyz.example.com')
    end
  end

  def test_query_host_unauthorized
    icinga_result = '{"error":401.0,"status":"Unauthorized. Please check your user credentials."}'
    stub_request(:get, "https://localhost:5665/v1/objects/hosts/xyz.example.com?attrs=vars&attrs=address&attrs=address6&attrs=templates").
      to_return(:status => 401, :body => icinga_result)

    assert_raises Proxy::Monitoring::AuthenticationError do
      @provider.query_host('xyz.example.com')
    end
  end

  def test_query_host_with_vars
    icinga_result = '{"results":[{"attrs":{"address":"1.1.1.1","address6":"2001:db8::1","templates":["xyz.example.com","foreman-host"],"vars":{"os":"Linux","disks":["/","/boot"]}},"joins":{},"meta":{},"name":"xyz.example.com","type":"Host"}]}'
    stub_request(:get, "https://localhost:5665/v1/objects/hosts/xyz.example.com?attrs=vars&attrs=address&attrs=address6&attrs=templates").
      to_return(:status => 200, :body => icinga_result)

    attributes = {
      'ip' => '1.1.1.1',
      'ip6' => '2001:db8::1',
      'os' => 'Linux',
      'disks' => [ '/', '/boot' ]
    }
    data = @provider.query_host('xyz.example.com')

    assert_equal attributes, data
  end

  def test_query_host_with_template
    icinga_result = '{"results":[{"attrs":{"address":"1.1.1.1","address6":"2001:db8::1","templates":["xyz.example.com","Foreman Host"],"vars":null},"joins":{},"meta":{},"name":"xyz.example.com","type":"Host"}]}'
    stub_request(:get, "https://localhost:5665/v1/objects/hosts/xyz.example.com?attrs=vars&attrs=address&attrs=address6&attrs=templates").
      to_return(:status => 200, :body => icinga_result)

    attributes = {
      'ip' => '1.1.1.1',
      'ip6' => '2001:db8::1',
      'templates' => [ 'Foreman Host' ],
    }
    data = @provider.query_host('xyz.example.com')

    assert_equal attributes, data
  end
  def test_create_host
    icinga_result = '{"results":[{"code":200.0,"status":"Object was created"}]}'
    stub_request(:put, "https://localhost:5665/v1/objects/hosts/xyz.example.com").
      with(
        :body => '{"templates":["foreman-host"],"attrs":{"address":"1.1.1.1","address6":"2001:db8::1"}}'
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
        :body => '{"templates":["foreman-host"],"attrs":{"address":"1.1.1.1","address6":"2001:db8::1"}}'
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
    stub_request(:post, "https://localhost:5665/v1/actions/schedule-downtime").
      with(:body => '{"type":"Host","filter":"host.name==\"xyz.example.com\"","author":"Foreman","comment":"Downtime by Foreman","start_time":"1491819090","end_time":"1491819095","duration":1000}').
      to_return(:status => 200, :body => icinga_result)
    @provider.set_downtime_host('xyz.example.com', 'Foreman', 'Downtime by Foreman', '1491819090', '1491819095')
  end

  def test_set_downtime_host_all_services
    icinga_result = '{"results":[{"code":200.0,"legacy_id":2.0,"name":"xyz.example.com!xyz.example.com-1491819090-1","status":"Successfully scheduled downtime \'xyz.example.com!xyz.example.com-1491819090-1\' for object \'xyz.example.com\'."}]}'
    stub_request(:post, "https://localhost:5665/v1/actions/schedule-downtime").
      with(:body => '{"type":"Host","filter":"host.name==\"xyz.example.com\"","author":"Foreman","comment":"Downtime by Foreman","start_time":"1491819090","end_time":"1491819095","duration":1000,"all_services":true}').
      to_return(:status => 200, :body => icinga_result)
    @provider.set_downtime_host('xyz.example.com', 'Foreman', 'Downtime by Foreman', '1491819090', '1491819095', all_services: true)
  end

  def test_remove_downtime_host
    icinga_result = '{"results":[{"code":200.0,"status":"Successfully removed all downtimes for object \'xyz.example.com\'."}]}'
    stub_request(:post, "https://localhost:5665/v1/actions/remove-downtime").
      with(:body => '{"type":"Host","filter":"host.name==\"xyz.example.com\"","author":"Foreman","comment":"Downtime by Foreman"}').
      to_return(:status => 200, :body => icinga_result)
    @provider.remove_downtime_host('xyz.example.com', 'Foreman', 'Downtime by Foreman')
  end
end
