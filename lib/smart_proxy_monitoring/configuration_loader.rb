module ::Proxy::Monitoring
  class ConfigurationLoader
    def load_classes
      require 'smart_proxy_monitoring/dependency_injection'
      require 'smart_proxy_monitoring/monitoring_api'
    end
  end
end
