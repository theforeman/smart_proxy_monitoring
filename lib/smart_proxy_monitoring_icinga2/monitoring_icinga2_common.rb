module ::Proxy::Monitoring::Icinga2
  module Common
    private

    def with_event_counter(log_prefix, interval_count = 100, interval_seconds = 60)
      semaphore.synchronize do
        @counter ||= 0
        @timer ||= Time.now
        if @counter >= interval_count || (Time.now - @timer) > interval_seconds
          status = "#{log_prefix}: Observed #{@counter} events in the last #{(Time.now - @timer).round(2)} seconds."
          status += " #{@queue.length} items queued. #{@queue.num_waiting} threads waiting." unless @queue.nil?
          logger.info status
          @timer = Time.now
          @counter = 0
        end
        @counter += 1
      end
      yield
    end
  end
end
