require 'smart_proxy_monitoring_icinga2/monitoring_icinga2_main'
require 'smart_proxy_monitoring_icingadirector/director_client'
require 'json'

module Proxy::Monitoring::IcingaDirector
  class Provider < ::Proxy::Monitoring::Icinga2::Provider
    def query_host(host)
      response = client.get("host?name=#{host}")
      parse_response(response)
    end

    def create_host(host, attributes)
      payload = host_payload(host, attributes)
      check_templates_exist(payload[:imports])
      client.post('host', payload.to_json)
    end

    def update_host(host, attributes)
      payload = host_payload(host, attributes)
      check_templates_exist(payload[:imports])
      client.put("host?name=#{host}", payload.to_json)
    rescue RestClient::NotModified
      true
    end

    def remove_host(host)
      client.delete("host?name=#{host}")
    end

    private

    def check_templates_exist(templates)
      templates.each do |template|
        raise "Template #{template} not found." unless template_exists?(template)
      end
    end

    def template_exists?(template)
      result = client.get("host?name=#{template}")
      result = JSON.parse(result)
      result['object_type'] == 'template'
    rescue Proxy::Monitoring::NotFound
      false
    end

    def host_payload(host, attributes)
      {
        :object_name => host,
        :object_type => 'object',
        :address => attributes.delete('ip'),
        :address6 => attributes.delete('ip6'),
        :imports => attributes.delete('templates') || ['foreman_host'],
        :vars => attributes
      }
    end

    def parse_response(response)
      response = JSON.parse(response)
      ip = response.delete('address')
      ip6 = response.delete('address6')
      templates = response.delete('imports')
      result = {
        'ip' => ip,
        'ip6' => ip6,
      }
      result.merge!('templates' => templates) if templates != ['foreman_host']
      result.merge!(response['vars'] || {})
      result
    end

    def client
      DirectorClient.instance
    end
  end
end
