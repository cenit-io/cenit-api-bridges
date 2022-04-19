require 'openapi3_parser'

module Cenit
  module ApiBuilder
    document_type :OpenApiSpec do
      field :title, type: String
      field :specification, type: String

      validates_presence_of :specification
      validate :validate_specification

      before_save :parse_title
      before_destroy :check_apps

      def spec
        @spec ||= Openapi3Parser.load(specification)
        @spec
      end

      def parse_title
        self.title = spec.info.title if title.blank?
      end

      def validate_specification
        errors.add(:specification, "in not valid, #{spec.errors.map(&:message).uniq.join(', ')}.") unless spec.valid?
      end

      def check_apps
        criteria = { specification_id: self.id }
        apps = LocalServiceApplication.where(criteria).count + BridgingServiceApplication.where(criteria).count
        raise 'The spec cannot be deleted because it is being used in some applications' if apps != 0
      end

      def find_security_schemes(type)
        spec.components.security_schemes.detect { |_, v| v.type == type.to_s }.last
      end

      def default_options
        data = {
          target_api_base_url: spec.servers.first.try(:url) || 'http://api.demo.io',
          authorization_type: :none
        }

        if security_scheme = find_security_schemes(:oauth2)
          options = security_scheme.flows.authorization_code
          data.merge!(
            authorization_type: :oauth2,
            auth_url: options.authorization_url,
            access_token_url: options.token_url,
            client_id: '',
            client_secret: '',
          )
        elsif find_security_schemes(:http)
          data.merge!(authorization_type: :basic)
        elsif find_security_schemes(:apiKey)
          data.merge!(:callback)
        end
      end
    end
  end
end