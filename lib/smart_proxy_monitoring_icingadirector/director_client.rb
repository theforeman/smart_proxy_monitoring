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
    rescue RestClient::NotFound
      raise Proxy::Monitoring::NotFound.new("Icinga Director returned not found for #{url}.")
    end

    def post(url, payload)
      logger.debug "IcingaDirector: POST request to #{url} with payload: #{payload}"
      client(url).post(payload).body
    end

    def put(url, payload)
      logger.debug "IcingaDirector: PUT request to #{url} with payload: #{payload}"
      client(url).put(payload).body
    end

    def delete(url)
      logger.debug "IcingaDirector: DELETE request to #{url}"
      client(url).delete.body
    rescue RestClient::NotFound
      raise Proxy::Monitoring::NotFound.new("Icinga Director returned not found for #{url}.")
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

    def baseurl
      Proxy::Monitoring::IcingaDirector::Plugin.settings.director_url + '/'
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
