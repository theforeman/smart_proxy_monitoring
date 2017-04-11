module ::Proxy::Monitoring::IcingaDirector
  class Plugin < ::Proxy::Provider
    plugin :monitoring_icingadirector, ::Proxy::Monitoring::VERSION

    default_settings verify_ssl: true

    requires :monitoring, ::Proxy::Monitoring::VERSION
    requires :monitoring_icinga2, ::Proxy::Monitoring::VERSION

    load_classes ::Proxy::Monitoring::IcingaDirector::PluginConfiguration
    load_dependency_injection_wirings ::Proxy::Monitoring::IcingaDirector::PluginConfiguration
  end
end
