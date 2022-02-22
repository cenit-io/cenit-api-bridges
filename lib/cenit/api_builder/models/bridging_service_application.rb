require 'cenit/api_builder/models/bridging_service'

module Cenit
  module ApiBuilder
    document_type :BridgingServiceApplication do
      field :namespace, type: String
      field :listening_path, type: String
      field :target_api_base_url, type: String

      belongs_to :specification, class_name: Setup::ApiSpec.name, inverse_of: nil
      belongs_to :connection, class_name: Setup::Connection.name, inverse_of: nil

      has_many :services, class_name: BridgingService.name, inverse_of: :application

      validates_presence_of :namespace, :listening_path, :target_api_base_url, :specification

      validates_length_of :namespace, minimum: 3, maximum: 15
      validates_length_of :listening_path, minimum: 3, maximum: 15

      validates_format_of :namespace, with: /\A[a-z][a-z0-9]*\Z/i
      validates_format_of :listening_path, with: /\A[a-z0-9]+([_-][a-z0-9]+)*\Z/
      validates_format_of :target_api_base_url, with: /\Ahttp(s)?:\/\/([\w-]+\.)+[a-z]{2,3}(\/.*)*\Z/

      validates_uniqueness_of :listening_path, scope: :namespace

      after_save :setup_connection, :setup_services
      before_destroy :destroy_connection, :destroy_services

      def spec
        @spec ||= Psych.load(self.specification.specification).deep_symbolize_keys
      end

      def setup_connection
        return if target_api_base_url == self.connection.try(:url)

        current_connection = self.connection

        criteria = { namespace: self.namespace, name: 'default_connection' }
        self.connection ||= Setup::Connection.where(criteria).first || Setup::Connection.new(criteria)

        self.connection.url = self.target_api_base_url
        self.connection.save!

        save! if self.connection != current_connection
      end

      def setup_services
        return unless services.count == 0

        priority = 0
        spec[:paths].keys.each do |path|
          %i[get post delete puth].each do |method|
            next unless spec[:paths][path][method]

            setup_service(spec[:paths][path][method], path.to_s, method.to_s, priority)
            priority += 1
          end
        end
      end

      def setup_service(spec, path, method, priority)
        service = Cenit::ApiBuilder::BridgingService.new(
          priority: priority,
          active: false,
          listen: { method: method, path: path },
          metadata: { path: path, method: method, spec: spec },
          application: self,
        )
        service.save!
      end

      def destroy_connection
        connection.try(:destroy)
      end

      def destroy_services
        services.each(&:destroy)
      end
    end
  end
end
