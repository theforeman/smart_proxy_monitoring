require 'rest-client'
require 'uri'

module ::Proxy::Monitoring::IcingaDirector
  class DirectorClient
    include ::Proxy::Log

    def self.instance
      @instance ||= new
    end

    def client(url)
      RestClient::Resource.new(
        request_url(url),
        request_options
      )
    end

    def request_url(url)
      URI.join(baseurl, url).to_s
    end

    def get(url)
      logger.debug "IcingaDirector: GET request to #{url}"
      client(url).get.body
    rescue StandardError => e
      raise handle_http_exception(e, url)
    end

    def post(url, payload)
      logger.debug "IcingaDirector: POST request to #{url} with payload: #{payload}"
      client(url).post(payload).body
    rescue StandardError => e
      raise handle_http_exception(e, url)
    end

    def put(url, payload)
      logger.debug "IcingaDirector: PUT request to #{url} with payload: #{payload}"
      client(url).put(payload).body
    rescue StandardError => e
      raise handle_http_exception(e, url)
    end

    def delete(url)
      logger.debug "IcingaDirector: DELETE request to #{url}"
      client(url).delete.body
    rescue StandardError => e
      raise handle_http_exception(e, url)
    end

    private

    def request_options
      {
        headers: request_headers,
        ssl_ca_file: cacert,
        verify_ssl: verify_ssl?
      }.merge(auth_options)
    end

    def auth_options
      return {} unless basic_auth?
      {
        user: user,
        password: password,
      }
    end

    def basic_auth?
      user && password
    end

    def request_headers
      {
        'Accept' => 'application/json'
      }
    end

    def handle_http_exception(e, url)
      case e
      when RestClient::ResourceNotFound
        Proxy::Monitoring::NotFound.new("Icinga Director returned not found for #{request_url(url)}.")
      when RestClient::Unauthorized
        Proxy::Monitoring::AuthenticationError.new("Error authenicating to Icinga Director at #{request_url(url)}: #{e.message}")
      when RestClient::NotModified
        raise
      else
        Proxy::Monitoring::Error.new("Error connecting to Icinga Director at #{request_url(url)}: #{e.message}")
      end
    end

    def baseurl
      "#{Proxy::Monitoring::IcingaDirector::Plugin.settings.director_url}/"
    end

    def user
      Proxy::Monitoring::IcingaDirector::Plugin.settings.director_user
    end

    def password
      Proxy::Monitoring::IcingaDirector::Plugin.settings.director_password
    end

    def cacert
      Proxy::Monitoring::IcingaDirector::Plugin.settings.director_cacert
    end

    def verify_ssl?
      Proxy::Monitoring::Icinga2::Plugin.settings.verify_ssl
    end
  end
end
