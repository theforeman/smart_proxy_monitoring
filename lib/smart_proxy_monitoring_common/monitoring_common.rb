module Proxy::Monitoring
  class Error < RuntimeError; end
  class NotFound < RuntimeError; end
  class AuthenticationError < RuntimeError; end

  class Provider
    def query_host(host)
      raise NotImplementedError
    end

    def create_host(host, attributes)
      raise NotImplementedError
    end

    def update_host(host, attributes)
      raise NotImplementedError
    end

    def remove_host(host)
      raise NotImplementedError
    end

    def remove_downtime_host(host, author, comment)
      raise NotImplementedError
    end

    def set_downtime_host(host, author, comment, start_time, end_time, all_services: nil, **)
      raise NotImplementedError
    end
  end
end
