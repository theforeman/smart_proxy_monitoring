require 'sinatra'
require 'smart_proxy_monitoring/monitoring_plugin'

module Proxy::Monitoring
  class Api < ::Sinatra::Base
    extend Proxy::Monitoring::DependencyInjection
    inject_attr :monitoring_provider, :server

    include ::Proxy::Log
    helpers ::Proxy::Helpers
    authorize_with_trusted_hosts
    authorize_with_ssl_client

    delete '/host/:host' do |host|
      begin
        validate_dns_name!(host)
        host = strip_domain(host)

        server.remove_host(host)
      rescue Proxy::Monitoring::NotFound => e
        log_halt 404, e
      rescue Proxy::Monitoring::ConnectionError => e
        log_halt 503, e
      rescue Exception => e
        log_halt 400, e
      end
    end

    post '/downtime/host/:host?' do |host|
      author = params[:author] || 'foreman'
      comment = params[:comment] || 'triggered by foreman'
      start_time = params[:start_time] || Time.now.to_i
      end_time = params[:end_time] || (Time.now.to_i + (24 * 3600))

      begin
        validate_dns_name!(host)
        host = strip_domain(host)

        server.set_downtime_host(host, author, comment, start_time, end_time)
      rescue Proxy::Monitoring::NotFound => e
        log_halt 404, e
      rescue Proxy::Monitoring::ConnectionError => e
        log_halt 503, e
      rescue Exception => e
        log_halt 400, e
      end
    end

    delete '/downtime/host/:host?' do |host|
      author = params[:author] || 'foreman'
      comment = params[:comment] || 'triggered by foreman'

      begin
        validate_dns_name!(host)
        host = strip_domain(host)

        server.remove_downtime_host(host, author, comment)
      rescue Proxy::Monitoring::NotFound => e
        log_halt 404, e
      rescue Proxy::Monitoring::ConnectionError => e
        log_halt 503, e
      rescue Exception => e
        log_halt 400, e
      end
    end

    def validate_dns_name!(name)
      raise Proxy::Monitoring::Error.new("Invalid DNS name #{name}") unless name =~ /^([a-zA-Z0-9]([-a-zA-Z0-9]+)?\.?)+$/
    end

    def strip_domain(name)
      domain = Proxy::Monitoring::Plugin.settings.strip_domain
      name.slice!(domain) unless domain.nil?
      name
    end
  end
end
