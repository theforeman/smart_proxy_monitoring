require 'test_helper'
require 'smart_proxy_monitoring'
require 'smart_proxy_monitoring/dependency_injection'
require 'smart_proxy_monitoring/monitoring_api'

ENV['RACK_ENV'] = 'test'

class MonitoringApiTest < Test::Unit::TestCase
  include Rack::Test::Methods

  class MonitoringApiTestProvider
    def set_downtime_host(host, author, comment, start_time, end_time); end

    def remove_downtime_host(host, author, comment); end

    def query_host(host); end

    def remove_host(host); end

    def create_host(host, attributes); end

    def update_host(host, attributes); end
  end

  def app
    app = Proxy::Monitoring::Api.new
    app.helpers.server = @server
    app
  end

  def setup
    @server = MonitoringApiTestProvider.new
  end

  def test_set_downtime_host
    post '/downtime/host/my.example.com'
    assert last_response.ok?, "Last response was not ok: #{last_response.status} #{last_response.body}"
  end

  def test_set_downtime_host_invalid_hostname
    post '/downtime/host/++'
    assert_equal 400, last_response.status
    assert_equal 'Invalid DNS name ++', last_response.body
  end

  def test_set_downtime_host_non_existant_host
    @server.expects(:set_downtime_host).raises(Proxy::Monitoring::NotFound)
    post '/downtime/host/abc.example.com'

    assert_equal 404, last_response.status
  end

  def test_set_downtime_host_with_connection_error
    @server.expects(:set_downtime_host).raises(Proxy::Monitoring::ConnectionError)
    post '/downtime/host/my.example.com'

    assert_equal 503, last_response.status
  end

  def test_remove_downtime_host
    delete '/downtime/host/my.example.com'
    assert last_response.ok?, "Last response was not ok: #{last_response.status} #{last_response.body}"
  end

  def test_remove_downtime_host_invalid_hostname
    delete '/downtime/host/++'
    assert_equal 400, last_response.status
    assert_equal 'Invalid DNS name ++', last_response.body
  end

  def test_remove_downtime_host_non_existant_host
    @server.expects(:remove_downtime_host).raises(Proxy::Monitoring::NotFound)
    delete '/downtime/host/abc.example.com'

    assert_equal 404, last_response.status
  end

  def test_remove_downtime_host_with_connection_error
    @server.expects(:remove_downtime_host).raises(Proxy::Monitoring::ConnectionError)
    delete '/downtime/host/my.example.com'

    assert_equal 503, last_response.status
  end

  def test_remove_host
    delete '/host/my.example.com'
    assert last_response.ok?, "Last response was not ok: #{last_response.status} #{last_response.body}"
  end

  def test_remove_host_invalid_hostname
    delete '/host/++'
    assert_equal 400, last_response.status
    assert_equal 'Invalid DNS name ++', last_response.body
  end

  def test_remove_host_non_existant_host
    @server.expects(:remove_host).raises(Proxy::Monitoring::NotFound)
    delete '/host/abc.example.com'

    assert_equal 404, last_response.status
  end

  def test_remove_host_with_connection_error
    @server.expects(:remove_host).raises(Proxy::Monitoring::ConnectionError)
    delete '/host/my.example.com'

    assert_equal 503, last_response.status
  end

  def test_create_host
    body = {:attributes => {:ip => '1.1.1.1'}}.to_json
    put '/host/my.example.com', body, "CONTENT_TYPE" => "application/json"
    assert last_response.ok?, "Last response was not ok: #{last_response.status} #{last_response.body}"
  end

  def test_update_host
    body = {:attributes => {:ip => '1.1.1.1'}}.to_json
    post '/host/my.example.com', body, "CONTENT_TYPE" => "application/json"
    assert last_response.ok?, "Last response was not ok: #{last_response.status} #{last_response.body}"
  end

  def test_query_host
    get '/host/my.example.com'
    assert last_response.ok?, "Last response was not ok: #{last_response.status} #{last_response.body}"
  end

  def test_query_host_non_existant_host
    @server.expects(:query_host).raises(Proxy::Monitoring::NotFound)
    get '/host/abc.example.com'

    assert_equal 404, last_response.status
  end

end
