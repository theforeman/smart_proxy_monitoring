require 'smart_proxy_monitoring_icinga2/icinga2_client'

module Proxy::Monitoring::Icinga2
  class Provider < ::Proxy::Monitoring::Provider
    include Proxy::Log
    include Proxy::Util

    ICINGA_HOST_ATTRS = %w(display_name address address6 templates)

    ICINGA_ATTR_MAPPING = {
      'ip' => 'address',
      'ip6' => 'address6',
    }.freeze

    def create_host(host, attributes)
      request_url = "/objects/hosts/#{host}"

      result = with_errorhandling("Create #{host}") do
        Icinga2Client.put(request_url, host_data(attributes).to_json)
      end
      result.to_json
    end

    def update_host(host, attributes)
      request_url = "/objects/hosts/#{host}"

      result = with_errorhandling("Create #{host}") do
        Icinga2Client.post(request_url, host_data(attributes).to_json)
      end
      result.to_json
    end

    def remove_host(host)
      request_url = "/objects/hosts/#{host}?cascade=1"

      result = with_errorhandling("Remove #{host}") do
        Icinga2Client.delete(request_url)
      end
      result.to_json
    end

    def remove_downtime_host(host, author, comment)
      request_url = "/actions/remove-downtime?type=Host&filter=host.name==\"#{host}\"\&\&author==\"#{author}\"\&\&comment=\"#{comment}\""
      data = {}

      result = with_errorhandling("Remove downtime from #{host}") do
        Icinga2Client.post(request_url, data.to_json)
      end
      result.to_json
    end

    def set_downtime_host(host, author, comment, start_time, end_time)
      request_url = "/actions/schedule-downtime?type=Host&filter=host.name==\"#{host}\""
      data = {
        'author' => author,
        'comment' => comment,
        'start_time' => start_time,
        'end_time' => end_time,
        'duration' => 1000
      }

      result = with_errorhandling("Set downtime on #{host}") do
        Icinga2Client.post(request_url, data.to_json)
      end
      result.to_json
    end

    private

    def host_data(attributes)
      data = {}

      data['templates'] = [ 'foreman-host' ] unless attributes.has_key?('templates')

      attributes.each do |key, value|
        key = ICINGA_ATTR_MAPPING[key] if ICINGA_ATTR_MAPPING.key?(key)
        key = "vars.#{key}" unless ICINGA_HOST_ATTRS.include?(key)
        data[key] = value
      end

      data
    end

    def with_errorhandling(action)
      response = yield
      logger.debug "Monitoring - Action successful: #{action}"
      result = JSON.parse(response.body)
      unless result.key?('results')
        logger.error "Invalid Icinga result or result with errors: #{result.inspect}"
        raise Proxy::Monitoring::Error.new("Icinga server at #{::Proxy::Monitoring::Icinga2::Plugin.settings.server} returned an invalid result.")
      end
      unless result['results'].first
        raise Proxy::Monitoring::NotFound.new("Icinga server at #{::Proxy::Monitoring::Icinga2::Plugin.settings.server} returned an empty result.")
      end
      if result['results'][0]['code'] != 200
        raise Proxy::Monitoring::Error.new("Icinga server at #{::Proxy::Monitoring::Icinga2::Plugin.settings.server} returned an error: #{result['results'][0]['code']} #{result['results'][0]['status']}")
      end
      result
    rescue JSON::ParserError => e
      raise Proxy::Monitoring::Error.new("Icinga server at #{::Proxy::Monitoring::Icinga2::Plugin.settings.server} returned invalid JSON: '#{e.message}'")
    rescue RestClient::Exception => e
      raise Proxy::Monitoring::Error.new("Icinga server at #{::Proxy::Monitoring::Icinga2::Plugin.settings.server} returned an error: '#{e.response}'")
    rescue Errno::ECONNREFUSED => e
      raise Proxy::Monitoring::ConnectionError.new("Icinga server at #{::Proxy::Monitoring::Icinga2::Plugin.settings.server} is not responding")
    rescue SocketError => e
      raise Proxy::Monitoring::ConnectionError.new("Icinga server '#{::Proxy::Monitoring::Icinga2::Plugin.settings.server}' is unknown")
    end
  end
end
