require 'cenit/api_builder/models/open_api_spec'

module Cenit
  module ApiBuilder
    module CommonServiceApplication
      extend ActiveSupport::Concern

      included do
        field :namespace, type: String
        field :listening_path, type: String

        belongs_to :specification, class_name: OpenApiSpec.name, inverse_of: nil
        belongs_to :access_token, class_name: Cenit::OauthAccessToken.name, inverse_of: nil

        validates_length_of :namespace, minimum: 3, maximum: 15
        validates_length_of :listening_path, minimum: 3, maximum: 15

        validates_format_of :namespace, with: /\A[a-z][a-z0-9]*\Z/i
        validates_format_of :listening_path, with: /\A[a-z0-9]+([_-][a-z0-9]+)*\Z/

        validates_uniqueness_of :listening_path

        before_destroy :destroy_services
      end

      def spec
        specification.spec
      end

      def setup_access_token
        return unless access_token.nil? || access_token.expired?

        app_id = Cenit::ApiBuilder.app.application_id
        access_grant = Cenit::OauthAccessGrant.where(application_id: app_id).first
        Cenit::OauthAccessGrant.new(application_id: app_id, scope: Cenit::ApiBuilder::SCOPE).save! unless access_grant

        self.set(
          access_token_id: Cenit::OauthAccessToken.create(
            tenant: Tenant.current,
            application_id: app_id,
            user_id: ::User.current.id,
            token_span: 0,
            data: {
              note: "#{self.class.name.split('::').last}-#{listening_path.humanize.parameterize}"
            }
          ).id
        )
      end

      def destroy_services
        services.each(&:destroy)
      end
    end
  end
end
