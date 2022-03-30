require 'cenit/api_builder/models/open_api_spec'
require 'cenit/api_builder/models/bridging_service'
require 'cenit/api_builder/models/common_service_application'

module Cenit
  module ApiBuilder
    document_type :BridgingServiceApplication do
      include CommonServiceApplication

      belongs_to :connection, class_name: Setup::Connection.name, inverse_of: nil

      has_many :services, class_name: BridgingService.name, inverse_of: :application

      validates_presence_of :namespace, :listening_path, :specification

      validates_format_of :target_api_base_url,
        allow_blank: true,
        with: %r{\Ahttp(s)?://((25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])(\.(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])){3}|([\w-]+\.)+[a-z]{2,3})(:\d+)?(/.*)*\Z}

      # before_save :setup_target_api_base_url
      after_save :setup_connection, :setup_access_token, :setup_services
      before_destroy :destroy_connection

      def target_api_base_url
        get_connection.url
      end

      def target_api_base_url=(value)
        get_connection.update(url: value.blank? ? spec.servers.first.url : value)
      end

      def get_connection
        return @conn unless @conn.nil?

        @conn = self.connection || begin
          criteria = { namespace: namespace, name: 'default_connection' }
          url = spec.servers.first.try(:url) || 'http://api.demo.io'
          Setup::Connection.where(criteria).first || Setup::Connection.create_from_json(criteria.merge(url: url))
        end
      end

      def setup_connection
        conn_id = get_connection.id
        self.set(connection_id: conn_id) if connection_id != conn_id
      end

      def setup_services
        return unless services.count == 0

        priority = 0
        spec.paths.keys.each do |path|
          %w[get post delete puth].each do |method|
            next unless spec.paths[path][method]

            setup_service(spec.paths[path][method], path, method, priority)
            priority += 1
          end
        end
      end

      def setup_service(_spec, path, method, priority)
        service = Cenit::ApiBuilder::BridgingService.new(
          priority: priority,
          active: false,
          listen: { method: method, path: path },
          metadata: { path: path, method: method },
          application: self
        )
        service.save
      end

      def destroy_connection
        connection.try(:destroy)
      end
    end
  end
end
