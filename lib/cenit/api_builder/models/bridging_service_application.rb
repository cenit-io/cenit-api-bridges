require 'cenit/api_builder/models/open_api_spec'
require 'cenit/api_builder/models/bridging_service'
require 'cenit/api_builder/models/common_service_application'
require 'cenit/api_builder/models/bridging_service_application_conn'
require 'cenit/api_builder/models/bridging_service_application_auth'

module Cenit
  module ApiBuilder
    document_type :BridgingServiceApplication do
      include CommonServiceApplication
      include BridgingServiceApplicationConn
      include BridgingServiceApplicationAuth

      has_many :services, class_name: BridgingService.name, inverse_of: :application

      validates_presence_of :namespace, :listening_path, :specification

      validates_format_of :target_api_base_url,
        allow_blank: true,
        with: %r{\Ahttp(s)?://((25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])(\.(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])){3}|([\w-]+\.)+[a-z]{2,3})(:\d+)?(/.*)*\Z}

      after_save :setup_access_token, :setup_services

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

      def schema
        1+1
      end
    end
  end
end
