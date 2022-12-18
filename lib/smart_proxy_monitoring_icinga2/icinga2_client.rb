require 'json'
require 'uri'
require 'rest-client'
require 'socket'
require 'base64'

module ::Proxy::Monitoring::Icinga2
  class Icinga2Client
    class << self
      def client(request_url)
        headers = {
          'Accept' => 'application/json'
        }

        options = {
          headers: headers,
          user: user,
          ssl_ca_file: cacert,
          verify_ssl: ssl
        }

        auth_options = if certificate_request?
                         {
                           ssl_client_cert: cert,
                           ssl_client_key: key
                         }
                       else
                         {
                           password: password
                         }
                       end
        options.merge!(auth_options)

        RestClient::Resource.new(
          [baseurl, request_url].join,
          options
        )
      end

      def events_socket(endpoint)
        uri = URI.parse([baseurl, endpoint].join)
        socket = TCPSocket.new(uri.host, uri.port)

        ssl_context = OpenSSL::SSL::SSLContext.new
        ssl_context.ca_file = cacert

        if ssl
          ssl_context.set_params(verify_mode: OpenSSL::SSL::VERIFY_PEER)
        else
          ssl_context.set_params(verify_mode: OpenSSL::SSL::VERIFY_NONE)
        end

        if certificate_request?
          ssl_context.cert = cert
          ssl_context.key = key
        end

        ssl_socket = OpenSSL::SSL::SSLSocket.new(socket, ssl_context)
        ssl_socket.sync_close = true
        ssl_socket.connect

        ssl_socket.write "POST #{uri.request_uri} HTTP/1.1\r\n"
        ssl_socket.write "Accept: application/json\r\n"
        unless certificate_request?
          auth = Base64.encode64("#{user}:#{password}")
          ssl_socket.write "Authorization: Basic #{auth}"
        end
        ssl_socket.write "\r\n"

        ssl_socket
      end

      def get(url)
        client(url).get
      end

      def post(url, data)
        client(url).post(data)
      end

      def put(url, data)
        client(url).put(data)
      end

      def delete(url)
        client(url).delete
      end

      def cert
        file = Proxy::Monitoring::Icinga2::Plugin.settings.api_usercert
        return unless !file.nil? && File.file?(file)

        OpenSSL::X509::Certificate.new(File.read(file))
      end

      def key
        file = Proxy::Monitoring::Icinga2::Plugin.settings.api_userkey
        return unless !file.nil? && File.file?(file)

        OpenSSL::PKey::RSA.new(File.read(file))
      end

      def cacert
        Proxy::Monitoring::Icinga2::Plugin.settings.api_cacert
      end

      def user
        Proxy::Monitoring::Icinga2::Plugin.settings.api_user
      end

      def password
        Proxy::Monitoring::Icinga2::Plugin.settings.api_password
      end

      def ssl
        Proxy::Monitoring::Icinga2::Plugin.settings.verify_ssl
      end

      def certificate_request?
        cert && key
      end

      def baseurl
        "https://#{Proxy::Monitoring::Icinga2::Plugin.settings.server}:#{Proxy::Monitoring::Icinga2::Plugin.settings.api_port}/v1"
      end
    end
  end
end
