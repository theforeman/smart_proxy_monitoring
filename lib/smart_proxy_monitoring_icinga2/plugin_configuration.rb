module ::Proxy::Monitoring::Icinga2
  class PluginConfiguration
    def load_classes
      require 'smart_proxy_monitoring_common/monitoring_common'
      require 'smart_proxy_monitoring_icinga2/monitoring_icinga2_main'
      require 'smart_proxy_monitoring_icinga2/monitoring_icinga2_common'
      require 'smart_proxy_monitoring_icinga2/icinga2_upload_queue'
      require 'smart_proxy_monitoring_icinga2/icinga2_client'
      require 'smart_proxy_monitoring_icinga2/icinga2_initial_importer'
      require 'smart_proxy_monitoring_icinga2/icinga2_api_observer'
      require 'smart_proxy_monitoring_icinga2/icinga2_result_uploader'
    end

    def load_dependency_injection_wirings(container_instance, settings)
      container_instance.dependency :monitoring_provider, lambda { ::Proxy::Monitoring::Icinga2::Provider.new }
      container_instance.singleton_dependency :icinga2_upload_queue, lambda { ::Proxy::Monitoring::Icinga2::Icinga2UploadQueue.new }
      container_instance.singleton_dependency :icinga2_api_observer, (lambda do
        ::Proxy::Monitoring::Icinga2::Icinga2ApiObserver.new(container_instance.get_dependency(:icinga2_upload_queue))
      end)
      container_instance.singleton_dependency :icinga2_result_uploader, (lambda do
        ::Proxy::Monitoring::Icinga2::Icinga2ResultUploader.new(container_instance.get_dependency(:icinga2_upload_queue))
      end)
      container_instance.singleton_dependency :icinga2_initial_importer, (lambda do
        ::Proxy::Monitoring::Icinga2::Icinga2InitialImporter.new(container_instance.get_dependency(:icinga2_upload_queue))
      end)
    end
  end
end
