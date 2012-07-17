module Fog
  module Rackspace
    module Requests
      include Fog::Rackspace::Authentication

      def initialize(endpoint, options)
        @uri = URI.parse(endpoint)
        @options = options
        @persistent = options[:persistent] || false
        @connection_options = options[:connection_options] || {}
        @connection = Fog::Connection.new(@uri.to_s, @persistent, @connection_options)
      end

      def request(params)
        begin
          authenticate(@options, @connection_options)
          try_request(params)
        rescue Exception => e
          # TODO: Rescue and instantiate Rackspace-specific exceptions.
          # - Unauthorized
          # - HTTP Status Error
          # - Not Found
          # - Bad Request
          # - Conflict
          # - Internal Server Error
          # - Service Unavailable
        end
      end

      private

      def try_request(params)
        # TODO: Make headers work.
        parameters = params.merge!({
          :headers => {
            'Content-Type' => 'application/json',
            'X-Auth-Token' => @auth_token
          },
          :host => @uri.host,
          :path => URI.join(@uri.path, params[:path])
        })

        response = @connection.request(parameters)
        response.body = Fog::JSON.decode(response.body) unless response.body.empty?
        response
      end
    end
  end
end
