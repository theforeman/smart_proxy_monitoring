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

    http_rackup_path File.expand_path('monitoring_http_config.ru', File.expand_path('../', __FILE__))
    https_rackup_path File.expand_path('monitoring_http_config.ru', File.expand_path('../', __FILE__))

    load_classes ::Proxy::Monitoring::ConfigurationLoader
  end
end
