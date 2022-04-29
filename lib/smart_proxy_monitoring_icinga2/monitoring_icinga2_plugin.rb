module ::Proxy::Monitoring::Icinga2
  class Plugin < ::Proxy::Provider
    plugin :monitoring_icinga2, ::Proxy::Monitoring::VERSION

    default_settings server: 'localhost'
    default_settings api_port: '5665'
    default_settings verify_ssl: true
    expose_setting :server
    expose_setting :api_user
    capability("config")
    capability("downtime")
    capability("status") unless Proxy::Monitoring::Plugin.settings.collect_status

    requires :monitoring, ::Proxy::Monitoring::VERSION

    start_services :icinga2_initial_importer, :icinga2_api_observer, :icinga2_result_uploader

    load_classes ::Proxy::Monitoring::Icinga2::PluginConfiguration
    load_dependency_injection_wirings ::Proxy::Monitoring::Icinga2::PluginConfiguration
  end
end
