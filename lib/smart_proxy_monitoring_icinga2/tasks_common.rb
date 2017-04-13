module ::Proxy::Monitoring::Icinga2
  module TasksCommon
    def start
      if activated?
        do_start
      else
        logger.info "Not starting #{action} because collect_status is disabled in settings."
      end
    end

    def action
      self.class.name.split('::').last
    end

    def activated?
      Proxy::Monitoring::Plugin.settings.collect_status
    end
  end
end
