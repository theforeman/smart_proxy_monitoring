require 'thread'
require 'socket'
require 'json'

module ::Proxy::Monitoring::Icinga2
  class Icinga2ApiObserver
    include ::Proxy::Log
    include ::Proxy::Monitoring::Icinga2::Common

    attr_reader :semaphore

    def initialize(queue)
      @queue = queue.queue
      @semaphore = Mutex.new
    end

    def monitor
      loop do
        logger.debug "Connecting to Icinga event monitoring api: #{Icinga2Client.baseurl}."

        ssl_socket = Icinga2Client.events_socket('/events?queue=foreman&types=StateChange&types=AcknowledgementSet&types=AcknowledgementCleared&types=DowntimeTriggered&types=DowntimeRemoved')

        logger.info 'Icinga event api monitoring started.'

        while line = ssl_socket.gets
          next unless line.chars.first == '{'

          with_event_counter('Icinga2 Event API Monitor') do
            begin
              parsed = JSON.parse(line)
              if @queue.size > 100_000
                @queue.clear
                logger.error 'Queue was full. Flushing. Events were lost.'
              end
              @queue.push(parsed)
            rescue JSON::ParserError => e
              logger.error "Icinga2 Event API Monitor: Malformed JSON: #{e.message}"
            end
          end

        end
        logger.info 'Icinga event api monitoring stopped.'
      end
    rescue Errno::ECONNREFUSED => e
      logger.error "Icinga Event Stream: Connection refused. Retrying in 5 seconds. Reason: #{e.message}"
      sleep 5
      retry
    rescue Exception => e
      logger.error "Error while monitoring: #{e.message}\n#{e.backtrace.join("\n")}"
      sleep 1
      retry
    ensure
      ssl_socket.sysclose unless ssl_socket.nil?
    end

    def start
      @thread = Thread.new { monitor }
      @thread.abort_on_exception = true
      @thread
    end

    def stop
      @thread.terminate unless @thread.nil?
    end
  end
end
