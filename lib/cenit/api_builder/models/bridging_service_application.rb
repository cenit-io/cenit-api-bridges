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

      after_save :setup_connection
      after_create :setup_services
      before_destroy :destroy_connection
      before_destroy :destroy_services

      def setup_connection
        return if target_api_base_url == self.connection.try(:url)

        current_connection = self.connection

        criteria = { namespace: 'ApiBuilder', name: "connection_#{self.id.to_s}" }
        self.connection ||= Setup::Connection.where(criteria).first || Setup::Connection.new(criteria)

        self.connection.url = self.target_api_base_url
        self.connection.save!

        save! if self.connection != current_connection
      end

      def setup_services
        position = 0
        spec = Psych.load(specification.specification).deep_symbolize_keys
        spec[:paths].keys.each do |path|
          %i[get post delete puth].each do |method|
            position += setup_service(spec, path, method, position) ? 1 : 0
          end
        end
      end

      def setup_service(spec, path, method, position)
        return false unless spec[:paths][path][method]

        service = Cenit::ApiBuilder::BridgingService.new(
          position: position,
          active: false,
          listen: { method: method.to_s.upcase, path: path.to_s },
          target: { method: method.to_s, path: path.to_s },
          webhook: setup_webhook(spec, path, method),
          application: { id: self.id },
        )
        service.save!
      end

      def setup_webhook(spec, path, method)
        service_spec = spec[:paths][path][method]

        path = path.to_s
        wh_template_parameters = path.scan(/\{([^\}]+)\}/).flatten.map { |n| { key: n, value: '-' } }
        wh_path = path.gsub(/\{([^\}]+)\}/, '{{\1}}')
        wh_data = {
          namespace: self.namespace,
          name: service_spec[:operationId] || "#{method}_#{path.parameterize.underscore}",
          method: method.to_s,
          path: wh_path,
          description: "#{service_spec[:summary]}\n\n#{service_spec[:description]}".strip,
          template_parameters: wh_template_parameters
        }

        Setup::PlainWebhook.create_from_json!(wh_data)
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
