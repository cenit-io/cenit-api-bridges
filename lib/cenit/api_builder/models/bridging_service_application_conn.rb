module Cenit
  module ApiBuilder
    module BridgingServiceApplicationConn
      extend ActiveSupport::Concern

      included do
        belongs_to :connection, class_name: Setup::Connection.name, inverse_of: nil

        field :target_api_base_url, type: String

        after_save :setup_connection
        before_destroy :destroy_authorization, :destroy_connection
      end

      def setup_connection_parameters(security_scheme)
        # ...
      end

      def target_api_base_url
        get_connection.url
      end

      def target_api_base_url=(value)
        get_connection&.update(url: value.blank? ? spec.servers.first.url : value)
      end

      def get_connection
        return @conn unless @conn.nil?

        @conn = self.connection ||= begin
          criteria = { namespace: namespace, name: 'default_connection' }
          Setup::Connection.where(criteria).first || create_default_connection(criteria)
        end
      end

      def create_default_connection(data)
        return nil if spec.nil?

        auth = get_authorization

        data[:url] = spec.servers.first.try(:url) || 'http://api.demo.io'
        data[:headers] = []
        data[:parameters] = []
        data[:template_parameters] = []
        data[:authorization] = { id: auth.id, _reference: true } unless auth.nil?

        spec.components.security_schemes.each do |_, scheme|
          next unless scheme.type == 'apiKey'

          tp_name = scheme.name.parameterize.underscore
          item = { key: scheme.name, value: "{{#{tp_name}}}" }

          data[:headers] << item if scheme.in == 'header'
          data[:parameters] << item if scheme.in == 'query'
        end

        Setup::Connection.create_from_json!(data)
      end

      def setup_connection
        conn_id = get_connection.id
        self.set(connection_id: conn_id) if connection_id != conn_id
      end

      def destroy_connection
        connection&.destroy
      end
    end
  end
end
