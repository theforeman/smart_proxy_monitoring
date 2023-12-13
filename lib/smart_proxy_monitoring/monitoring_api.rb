require 'sinatra'
require 'smart_proxy_monitoring/monitoring_plugin'
require 'json'

module Proxy::Monitoring
  class Api < ::Sinatra::Base
    extend Proxy::Monitoring::DependencyInjection
    inject_attr :monitoring_provider, :server

    include ::Proxy::Log
    helpers ::Proxy::Helpers
    authorize_with_trusted_hosts
    authorize_with_ssl_client

    get '/host/:host' do |host|
      log_provider_errors do
        validate_dns_name!(host)
        host = strip_domain(host)

        server.query_host(host).to_json
      end
    end

    put '/host/:host' do |host|
      log_provider_errors do
        validate_dns_name!(host)
        host = strip_domain(host)
        attributes = params[:attributes]
        logger.debug "Creating host #{host} object with attributes #{attributes.inspect}"

        server.create_host(host, attributes)
      end
    end

    post '/host/:host' do |host|
      log_provider_errors do
        validate_dns_name!(host)
        host = strip_domain(host)
        attributes = params[:attributes]
        logger.debug "Updating host #{host} object with attributes #{attributes.inspect}"

        server.update_host(host, attributes)
      end
    end

    delete '/host/:host' do |host|
      log_provider_errors do
        validate_dns_name!(host)
        host = strip_domain(host)
        logger.debug "Removing host #{host} object"

        server.remove_host(host)
      end
    end

    post '/downtime/host/:host?' do |host|
      author = params[:author] || 'foreman'
      comment = params[:comment] || 'triggered by foreman'
      start_time = params[:start_time] || Time.now.to_i
      end_time = params[:end_time] || (Time.now.to_i + (24 * 3600))
      all_services = params[:all_services].to_s == 'true'

      log_provider_errors do
        validate_dns_name!(host)
        host = strip_domain(host)

        server.set_downtime_host(host, author, comment, start_time, end_time, all_services: all_services)
      rescue ArgumentError
        server.set_downtime_host(host, author, comment, start_time, end_time)
      end
    end

    delete '/downtime/host/:host?' do |host|
      author = params[:author] || 'foreman'
      comment = params[:comment] || 'triggered by foreman'

      log_provider_errors do
        validate_dns_name!(host)
        host = strip_domain(host)

        server.remove_downtime_host(host, author, comment)
      end
    end

    def log_provider_errors
      yield
    rescue Proxy::Monitoring::NotFound => e
      log_halt 404, e
    rescue Proxy::Monitoring::ConnectionError => e
      log_halt 503, e
    rescue Proxy::Monitoring::AuthenticationError => e
      log_halt 500, e
    rescue Exception => e
      log_halt 400, e
    end

    def validate_dns_name!(name)
      raise Proxy::Monitoring::Error, "Invalid DNS name #{name}" unless /^([a-zA-Z0-9]([-a-zA-Z0-9]+)?\.?)+$/.match?(name)
    end

    def strip_domain(name)
      domain = Proxy::Monitoring::Plugin.settings.strip_domain
      name.slice!(domain) unless domain.nil?
      name
    end
  end
end
