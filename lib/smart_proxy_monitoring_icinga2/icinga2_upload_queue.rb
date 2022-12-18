module ::Proxy::Monitoring::Icinga2
  class Icinga2UploadQueue
    def queue
      @queue ||= Queue.new
    end
  end
end
