module Fog
  module Rackspace
    module Authentication
      US_ENDPOINT = 'https://identity.api.rackspacecloud.com'
      UK_ENDPOINT = 'https://lon.identity.api.rackspacecloud.com'

      attr_reader :auth_token, :auth_token_expiration, :service_catalog

      def authenticate(options, connection_options)
        renew_auth_token(options, connection_options) unless valid_token?
      end

      private

      def valid_token?
        return @auth_token && @auth_token_expiration > DateTime.now
      end

      def renew_auth_token(options, connection_options)
        auth_url = options[:rackspace_auth_url] || US_ENDPOINT
        auth_url = 'https://' + auth_url unless auth_url.start_with?('https://')
        uri = URI.parse(auth_url);

        credentials = credentials = {
          'auth' => {
            'RAX-KSKEY:apiKeyCredentials' => {
              'username' => options[:rackspace_username],
              'apiKey' => options[:rackspace_api_key]
            }
          }
        }

        connection = Fog::Connection.new(auth_url, false, connection_options)
        response = connection.request({
          :expect => [200, 203],
          :host => uri.host,
          :path => '/v2.0/tokens',
          :method => 'POST',
          :headers => {
            'Content-Type' => 'application/json'
          },
          :body => Fog::JSON.encode(credentials)
        })
        body = Fog::JSON.decode(response.body)

        @auth_token = body['access']['token']['id']
        @auth_token_expiration = DateTime.parse(body['access']['token']['expires'])
        @service_catalog = ServiceCatalog.new(body['access']['serviceCatalog'])
      end

      class ServiceCatalog
        def initialize(services)
          @services = []
          services.each do |data|
            @services << Service.new(data)
          end
        end

        def all
          @services
        end

        def find_by_type(type)
          @services.select { |s| s.type == type }
        end

        def get(name)
          @services.select { |s| s.name == name }.first
        end
      end

      class Service
        attr_reader :name, :type, :endpoints

        def initialize(attributes)
          @name = attributes['name']
          @type = attributes['type']
          @endpoints = attributes['endpoints'].map { |e| Endpoint.new(e) }
        end
      end

      class Endpoint
        attr_reader :tenant_id, :public_url, :internal_url, :region,
          :version_id, :version_info, :version_list

        def initialize(attributes)
          @tenant_id = attributes['tenantId']
          @public_url = attributes['publicURL']
          @internal_url = attributes['internalURL']
          @region = attributes['region']
          @version_id = attributes['versionId']
          @version_info = attributes['versionInfo']
          @version_list = attributes['versionList']
        end
      end
    end
  end
end
