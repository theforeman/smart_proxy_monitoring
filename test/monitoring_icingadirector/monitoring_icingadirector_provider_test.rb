require 'test_helper'
require 'smart_proxy_monitoring'

class MonitoringIcingaDirectorProviderTest < Test::Unit::TestCase
  def setup
    test_settings = {
      :director_url => 'https://localhost/icingaweb2/director',
    }
    Proxy::Monitoring::Icinga2::Plugin.load_test_settings({})
    Proxy::Monitoring::IcingaDirector::Plugin.load_test_settings(test_settings)
    @provider = Proxy::Monitoring::IcingaDirector::Provider.new
  end

  def test_query_host
    response_body = "{\"object_name\":\"xyz.example.com\",\"object_type\":\"object\",\"address\":\"1.1.1.1\",\"address6\":\"2001:db8::1\",\"imports\":[\"foreman_host\"]}"
    stub_request(:get, "https://localhost/icingaweb2/director/host?name=xyz.example.com").
    to_return(:status => 200, :body => response_body)

    attributes = {
      'ip' => '1.1.1.1',
      'ip6' => '2001:db8::1',
    }
    data = @provider.query_host('xyz.example.com')

    assert_equal attributes, data
  end

  def test_query_host_non_existent
    response_body = '{"error":"Failed to load icinga_host \"xyz.example.com\""}'
    stub_request(:get, "https://localhost/icingaweb2/director/host?name=xyz.example.com").
    to_return(:status => 404, :body => response_body)

    assert_raises Proxy::Monitoring::NotFound do
      @provider.query_host('xyz.example.com')
    end
  end

  def test_query_host_with_vars
    response_body = "{\"object_name\":\"xyz.example.com\",\"object_type\":\"object\",\"address\":\"1.1.1.1\",\"address6\":\"2001:db8::1\",\"imports\":[\"foreman_host\"],\"vars\":{\"os\":\"Linux\",\"disks\":[\"\\/\", \"\\/boot\"]}}"
    stub_request(:get, "https://localhost/icingaweb2/director/host?name=xyz.example.com").
    to_return(:status => 200, :body => response_body)

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
    response_body = "{\"object_name\":\"xyz.example.com\",\"object_type\":\"object\",\"address\":\"1.1.1.1\",\"address6\":\"2001:db8::1\",\"imports\":[\"Foreman Host\"]}"
    stub_request(:get, "https://localhost/icingaweb2/director/host?name=xyz.example.com").
    to_return(:status => 200, :body => response_body)

    attributes = {
      'ip' => '1.1.1.1',
      'ip6' => '2001:db8::1',
      'templates' => [ 'Foreman Host' ],
    }
    data = @provider.query_host('xyz.example.com')

    assert_equal attributes, data
  end

  def test_create_host
    stub_template_request
    request_body = "{\"object_name\":\"xyz.example.com\",\"object_type\":\"object\",\"address\":\"1.1.1.1\",\"address6\":\"2001:db8::1\",\"imports\":[\"foreman_host\"],\"vars\":{}}"
    response_body = "{\"object_name\":\"xyz.example.com\",\"object_type\":\"object\",\"address\":\"1.1.1.1\",\"address6\":\"2001:db8::1\",\"imports\":[\"foreman_host\"]}"
    stub_request(:post, "https://localhost/icingaweb2/director/host").
      with(
        :body => request_body,
    ).
    to_return(:status => 201, :body => response_body)

    attributes = {
      'ip' => '1.1.1.1',
      'ip6' => '2001:db8::1',
    }
    @provider.create_host('xyz.example.com', attributes)
  end

  def test_update_host
    stub_template_request
    request_body = "{\"object_name\":\"xyz.example.com\",\"object_type\":\"object\",\"address\":\"1.1.1.1\",\"address6\":\"2001:db8::1\",\"imports\":[\"foreman_host\"],\"vars\":{}}"
    response_body = "{\"object_name\":\"xyz.example.com\",\"object_type\":\"object\",\"address\":\"1.1.1.1\",\"address6\":\"2001:db8::1\",\"imports\":[\"foreman_host\"]}"
    stub_request(:put, "https://localhost/icingaweb2/director/host?name=xyz.example.com").
      with(
        :body => request_body,
    ).
    to_return(:status => 200, :body => response_body)

    attributes = {
      'ip' => '1.1.1.1',
      'ip6' => '2001:db8::1',
    }
    @provider.update_host('xyz.example.com', attributes)
  end

  def test_remove_host
    body = "{\"object_name\":\"xyz.example.com\",\"object_type\":\"object\",\"address\":\"1.1.1.1\",\"address6\":\"2001:db8::1\",\"imports\":[\"foreman_host\"],\"vars\":{}}"
    stub_request(:delete, "https://localhost/icingaweb2/director/host?name=xyz.example.com").
      to_return(:status => 200, :body => body)

    @provider.remove_host('xyz.example.com')
  end

  private

  def stub_template_request
    body = '{"check_command": "hostalive","object_name": "foreman_host", "object_type": "template"}'
    stub_request(:get, "https://localhost/icingaweb2/director/host?name=foreman_host").
      to_return(:status => 200, :body => body, :headers => {})
  end
end
