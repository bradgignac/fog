module Fog
  module Rackspace
    module Authentication
      attr_reader :auth_token, :auth_token_expiration, :service_catalog

      def authenticate
        renew_auth_token if needs_authentication?
      end

      def renew_auth_token
        # Make the request
      end

      def needs_authentication?
        return !@auth_token || token_expired?
      end

      def token_expired?
        @auth_token_expiration >= DateTime.now.utc
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
