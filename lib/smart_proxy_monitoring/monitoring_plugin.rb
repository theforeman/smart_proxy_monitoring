require 'smart_proxy_monitoring/version'

module Proxy::Monitoring
  class NotFound < RuntimeError; end
  class ConnectionError < RuntimeError; end
  class Error < RuntimeError; end

  class Plugin < ::Proxy::Plugin
    plugin 'monitoring', Proxy::Monitoring::VERSION

    uses_provider
    default_settings use_provider: 'monitoring_icinga2'
    default_settings collect_status: true
    expose_setting :collect_status
    expose_setting :strip_domain

    rackup_path File.expand_path('monitoring_http_config.ru', __dir__)

    load_classes ::Proxy::Monitoring::ConfigurationLoader
  end
end
