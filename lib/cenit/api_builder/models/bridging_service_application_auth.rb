module Cenit
  module ApiBuilder
    module BridgingServiceApplicationAuth
      extend ActiveSupport::Concern

      included do
        delegate :authorization, to: :connection, allow_nil: true
      end

      def get_authorization
        return @auth unless @auth.nil?

        @auth = self.authorization || begin
          criteria = { namespace: namespace, name: 'default_authorization' }
          Setup::Authorization.where(criteria).first || create_default_authorization
        end
      end

      def create_default_authorization
        return unless authorization.nil?

        auth = nil

        spec.security.first.try do |scheme|
          scheme.first.try do |name, scope|
            security_scheme = spec.components.security_schemes[name]
            auth = begin
              case security_scheme.type.to_s.to_sym
              when :apiKey
                create_callback_authorization(security_scheme)
              when :http
                create_basic_authorization(security_scheme)
              when :oauth2
                create_oaut2_authorization(security_scheme, scope)
              end
            end
          end
        end

        auth
      end

      def create_callback_authorization(security_scheme)
        return unless authorization.nil?

        endpoint = "#{Cenit.homepage}/app/api/builder/admin/bs_apps/#{self.id}/authorize/#{Tenant.current.id}"

        provider = Setup::GenericAuthorizationProvider.create_from_json!(
          { namespace: namespace, name: 'default_provider', authorization_endpoint: endpoint },
          { primary_fields: %i[namespace name] }
        )

        client = Setup::GenericAuthorizationClient.create_from_json!(
          { name: 'default_client', identifier: self.id.to_s, secret: '', provider: { id: provider.id, _reference: true } },
          { primary_fields: %i[provider name] }
        )

        code = 'callback_params.each { |k,v| template_parameters[k] = v }'
        callback = Setup::Algorithm.create_from_json!(
          {
            namespace: namespace,
            name: 'default_authorization_callback',
            code: code,
            parameters: [
              { name: 'callback_params' },
              { name: 'template_parameters' },
            ]
          },
          { primary_fields: %i[namespace name] }
        )

        Setup::GenericCallbackAuthorization.create_from_json!(
          {
            namespace: namespace,
            name: 'default_authorization',
            client: { id: client.id, _reference: true },
            callback_resolver: { id: callback.id, _reference: true },
          },
          { primary_fields: %i[client name] }
        )
      end

      def create_basic_authorization(security_scheme)
        # ...
      end

      def create_oaut2_authorization(security_scheme, scope)
        provider = ''
        client = ''
        auth = ''
      end

      def destroy_authorization
        if authorization && authorization.namespace == self.namespace && authorization.name =~ /^default_authorization/
          if authorization.respond_to?(:client)
            client = authorization.client
            provider = client.provider
            provider.destroy if provider.namespace == self.namespace && provider.name =~ /^default_provider/
            client.destroy
          end

          if authorization.respond_to?(:callback_resolver)
            alg = authorization.callback_resolver
            if alg&.name =~ /default_authorization_callback/
              alg.snippet&.destroy
              alg.destroy
            end
          end

          authorization.destroy
        end
      end
    end
  end
end
