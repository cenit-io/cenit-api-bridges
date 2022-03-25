require 'cenit/api_builder/models/open_api_spec'
require 'cenit/api_builder/models/bridging_service'
require 'cenit/api_builder/models/common_service_application'

module Cenit
  module ApiBuilder
    document_type :BridgingServiceApplication do
      include CommonServiceApplication

      field :target_api_base_url, type: String

      belongs_to :connection, class_name: Setup::Connection.name, inverse_of: nil

      has_many :services, class_name: BridgingService.name, inverse_of: :application

      validates_presence_of :namespace, :listening_path, :target_api_base_url, :specification

      validates_format_of :target_api_base_url, with: /\Ahttp(s)?:\/\/((25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])(\.(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])){3}|([\w-]+\.)+[a-z]{2,3})(:\d+)?(\/.*)*\Z/

      after_save :setup_connection, :setup_access_token, :setup_services
      before_destroy :destroy_connection

      def spec
        specification.spec
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

      def setup_access_token
        return unless self.access_token.nil?

        self.access_token = Cenit::OauthAccessToken.for(
          Cenit::ApiBuilder.app.application_id,
          Cenit::ApiBuilder::SCOPE,
          ::User.current,
          token_span: 0,
          note: "api-#{listening_path.humanize.parameterize}-token"
        )

        save!
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

      def setup_service(spec, path, method, priority)
        service = Cenit::ApiBuilder::BridgingService.new(
          priority: priority,
          active: false,
          listen: { method: method, path: path },
          metadata: { path: path, method: method },
          application: self,
        )
        service.save!
      end

      def destroy_connection
        connection.try(:destroy)
      end
    end
  end
end
