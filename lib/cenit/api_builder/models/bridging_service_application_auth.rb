module Cenit
  module ApiBuilder
    module BridgingServiceApplicationAuth
      extend ActiveSupport::Concern

      included do
        delegate :authorization, to: :connection, allow_nil: true

        field :auth_url, type: String
        field :access_token_url, type: String
        field :client_id, type: String
        field :client_secret, type: String
        field :scopes, type: String
      end

      def get_authorization
        return @auth unless @auth.nil?

        @auth = self.authorization || begin
          criteria = { namespace: namespace, name: 'default_authorization' }
          Setup::Authorization.where(criteria).first || create_default_authorization
        end
      end

      def get_authorization_client
        return @client unless @client.nil?

        @client = begin
          auth = get_authorization
          auth && auth.respond_to?(:client) ? auth.client : nil
        end
      end

      def authorization_type
        auth = get_authorization
        return 'none' unless auth

        return 'oauth2' if auth.is_a?(Setup::Oauth2Authorization)
        return 'basic' if auth.is_a?(Setup::BasicAuthorization)
        return 'callback' if auth.is_a?(Setup::GenericAuthorizationProvider)
      end

      def auth_url
        client = get_authorization_client
        return nil unless client

        client.provider.authorization_endpoint
      end

      def auth_url=(value)
        client = get_authorization_client
        return nil unless client

        client.provider.update(authorization_endpoint: value)
      end

      def access_token_url
        client = get_authorization_client
        return nil unless client

        client.provider.token_endpoint
      end

      def access_token_url=(value)
        client = get_authorization_client
        return nil unless client

        client.provider.update(token_endpoint: value)
      end

      def client_id
        client = get_authorization_client
        return nil unless client && client.respond_to?(:identifier)

        client.identifier
      end

      def client_id=(value)
        client = get_authorization_client
        return nil unless client && client.respond_to?(:identifier)

        client.update(identifier: value)
      end

      def client_secret
        client = get_authorization_client
        return nil unless client && client.respond_to?(:secret)

        client.secret
      end

      def client_secret=(value)
        client = get_authorization_client
        return nil unless client && client.respond_to?(:secret)

        client.update(secret: value)
      end

      def scopes
        auth = get_authorization
        return nil unless auth

        tp = auth.template_parameters.detect { |tp| tp.key == 'scopes' }
        tp ? tp.value : ''
      end

      def scopes=(value)
        auth = get_authorization
        return nil unless auth

        tp = auth.template_parameters.detect { |tp| tp.key == 'scopes' }
        tp.update(value: value)
      end

      private

      def find_security_schemes(type)
        spec.components.security_schemes.detect { |_, v| v.type == type.to_s }.last
      end

      def create_default_authorization
        return nil if spec.nil?

        return authorization unless authorization.nil?

        if security_scheme = find_security_schemes(:oauth2)
          create_oaut2_authorization(security_scheme)
        elsif security_scheme = find_security_schemes(:http)
          create_basic_authorization(security_scheme)
        elsif security_scheme = find_security_schemes(:apiKey)
          create_callback_authorization(security_scheme)
        end
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
          { primary_fields: %i[namespace name] }
        )
      end

      def create_basic_authorization(security_scheme)
        Setup::BasicAuthorization.create_from_json!(
          {
            namespace: namespace,
            name: 'default_authorization',
          },
          { primary_fields: %i[namespace name] }
        )
      end

      def create_oaut2_authorization(security_scheme)
        options = security_scheme.flows.authorization_code

        Cenit.fail('CenitIO only support OAuth2 with authorization-code type') if options.nil?

        provider = Setup::Oauth2Provider.create_from_json!(
          {
            namespace: namespace,
            name: 'default_provider',
            authorization_endpoint: options.authorization_url,
            response_type: 'code',
            token_endpoint: options.token_url,
            token_method: 'POST',
            refresh_token_strategy: 'default',
            scope_separator: ','
          },
          { primary_fields: %i[namespace name] }
        )

        client = Setup::RemoteOauthClient.create_from_json!(
          { name: 'default_client', provider: { _reference: true, id: provider.id } },
          { primary_fields: %i[provider name] }
        )

        scope = Setup::Oauth2Scope.create_from_json!(
          { name: '{{scopes}}', provider: { _reference: true, id: provider.id } },
          { primary_fields: %i[provider name] }
        )

        Setup::Oauth2Authorization.create_from_json!(
          {
            namespace: namespace,
            name: 'default_authorization',
            token_type: 'bot',
            client: { _reference: true, id: client.id, },
            parameters: [],
            template_parameters: [{ key: 'scopes', value: options.scopes.values.join(',') }],
            scopes: [{ _reference: true, id: scope.id }]
          }
        )
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
