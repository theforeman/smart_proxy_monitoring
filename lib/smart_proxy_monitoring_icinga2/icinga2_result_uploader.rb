require 'thread'

module ::Proxy::Monitoring::Icinga2
  class MonitoringResult < Proxy::HttpRequest::ForemanRequest
    def push_result(result)
      send_request(request_factory.create_post('api/monitoring_results', result))
    end
  end

  class Icinga2ResultUploader
    include ::Proxy::Log
    include ::Proxy::Monitoring::Icinga2::Common
    include TasksCommon

    attr_reader :semaphore

    def initialize(queue)
      @queue = queue.queue
      @semaphore = Mutex.new
    end

    def upload
      while change = @queue.pop
        with_event_counter('Icinga2 Result Uploader') do
          symbolize_keys_deep!(change)

          change[:timestamp] = change[:check_result][:schedule_end] if change.key?(:check_result)
          if change.key?(:downtime) && change[:downtime].is_a?(Hash)
            change[:host] = change[:downtime][:host_name] if change[:host].nil? || change[:host].empty?
            change[:service] = change[:downtime][:service_name] if change[:service].nil? || change[:service].empty?
          end

          if change[:service].nil? || change[:service].empty?
            change[:service] = 'Host Check'
          end

          case change[:type]
          when 'StateChange'
            transformed = { result: change[:check_result][:state] }
          when 'AcknowledgementSet'
            transformed = { acknowledged: true }
          when 'AcknowledgementCleared'
            transformed = { acknowledged: false }
          when 'DowntimeTriggered'
            transformed = { downtime: true }
          when 'DowntimeRemoved'
            transformed = { downtime: false }
          when '_parsed'
            transformed = change.dup.reject! { |k, _v| k == :type }
          else
            next
          end
          transformed.merge!(
            host: change[:host],
            service: change[:service],
            timestamp: change[:timestamp]
          )
          begin
            MonitoringResult.new.push_result(transformed.to_json)
          rescue Errno::ECONNREFUSED => e
            logger.error "Foreman refused connection when tried to upload monitoring result: #{e.message}"
            sleep 10
          rescue => e
            logger.error "Error while uploading monitoring results to Foreman: #{e.message}"
            sleep 1
            retry
          end
        end
      end
    end

    def do_start
      @thread = Thread.new { upload }
      @thread.abort_on_exception = true
      @thread
    end

    def stop
      @thread.terminate unless @thread.nil?
    end

    private

    def symbolize_keys_deep!(h)
      h.keys.each do |k|
        ks    = k.to_sym
        h[ks] = h.delete k
        symbolize_keys_deep! h[ks] if h[ks].is_a? Hash
      end
    end

    def add_domain(host)
      domain = Proxy::Monitoring::Plugin.settings.strip_domain
      host = "#{host}#{domain}" unless domain.nil?
      host
    end
  end
end
