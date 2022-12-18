require 'socket'
require 'json'

module ::Proxy::Monitoring::Icinga2
  class Icinga2InitialImporter
    include ::Proxy::Log
    include TasksCommon

    def initialize(queue)
      @queue = queue.queue
    end

    def monitor
      logger.debug 'Starting initial icinga import.'

      around_action('Initial Host Import') do
        import_hosts
      end

      around_action('Initial Services Import') do
        import_services
      end

      around_action('Initial Downtimes Import') do
        import_downtimes
      end

      logger.info 'Finished initial icinga import.'
    rescue Exception => e
      logger.error "Error during initial import: #{e.message}\n#{e.backtrace}"
    end

    def import_hosts
      results = Icinga2Client.get('/objects/hosts?attrs=name&attrs=last_check_result&attrs=acknowledgement')
      results = JSON.parse(results)
      results['results'].each do |result|
        next if result['attrs']['last_check_result'].nil?

        parsed = {
          host: result['attrs']['name'],
          result: result['attrs']['last_check_result']['state'],
          timestamp: result['attrs']['last_check_result']['schedule_end'],
          acknowledged: (result['attrs']['acknowledgement'] != 0),
          initial: true,
          type: '_parsed'
        }
        @queue.push(parsed)
      end
    end

    def import_services
      results = Icinga2Client.get('/objects/services?attrs=name&attrs=last_check_result&attrs=acknowledgement&attrs=host_name')
      results = JSON.parse(results)
      results['results'].each do |result|
        next if result['attrs']['last_check_result'].nil?

        parsed = {
          host: result['attrs']['host_name'],
          service: result['attrs']['name'],
          result: result['attrs']['last_check_result']['state'],
          timestamp: result['attrs']['last_check_result']['schedule_end'],
          acknowledged: (result['attrs']['acknowledgement'] != 0),
          initial: true,
          type: '_parsed'
        }
        @queue.push(parsed)
      end
    end

    def import_downtimes
      results = Icinga2Client.get('/objects/downtimes?attrs=host_name&attrs=service_name&attrs=trigger_time')
      results = JSON.parse(results)
      results['results'].each do |result|
        next unless result['attrs']['trigger_time'] != 0

        parsed = {
          host: result['attrs']['host_name'],
          service: result['attrs']['service_name'],
          downtime: true,
          initial: true,
          type: '_parsed'
        }
        @queue.push(parsed)
      end
    end

    def do_start
      @thread = Thread.new { monitor }
      @thread.abort_on_exception = true
      @thread
    end

    def stop
      @thread&.terminate
    end

    private

    def around_action(task)
      beginning_time = Time.now
      logger.info "Starting Task: #{task}."
      yield
      end_time = Time.now
      logger.info "Finished Task: #{task} in #{end_time - beginning_time} seconds."
    rescue Errno::ECONNREFUSED => e
      logger.error "Icinga Initial Importer: Connection refused in task #{task}. Reason: #{e.message}"
      logger.error "Icinga Initial Importer: Restarting #{task} in 5 seconds."
      sleep 5
      retry
    rescue JSON::ParserError => e
      logger.error "Icinga Initial Importer: Failed to parse JSON: #{e.message}"
    end
  end
end
