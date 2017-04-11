module ::Proxy::Monitoring::IcingaDirector
  class PluginConfiguration
    def load_classes
      require 'smart_proxy_monitoring_common/monitoring_common'
      require 'smart_proxy_monitoring_icingadirector/monitoring_icingadirector_main'
    end

    def load_dependency_injection_wirings(container_instance, settings)
      container_instance.dependency :monitoring_provider, lambda { ::Proxy::Monitoring::IcingaDirector::Provider.new }
    end
  end
end
