module Cenit
  module ApiBuilder
    module Helpers
      module AuthorizationsHelper
        def parse_from_record_to_response_authorization(record, with_details = false)
          type = record._type.split('::').last.underscore

          data = {
            id: record.id.to_s,
            namespace: record.namespace,
            name: record.name,
            type: type,
            authorized: record.authorized,
            url: "#{Cenit.homepage}/authorization/#{Tenant.current.id}/#{record.id}/authorize",
            updated_at: parse_datetime(record.updated_at),
            created_at: parse_datetime(record.created_at),
          }

          if with_details
            case type.to_sym
            when :oauth2_authorization
              tp = record.template_parameters.detect { |tp| tp.key == 'scopes' }
              scopes = tp ? tp.value : ''

              data.merge!(
                auth_url: record.client&.provider&.authorization_endpoint,
                access_token_url: record.client&.provider&.token_endpoint,
                client_id: record.client&.identifier,
                client_secret: record.client&.secret,
                scopes: scopes,
                parameters: record.parameters.map { |tp| { key: tp.key, value: tp.value } },
                template_parameters: record.template_parameters.map { |tp| { key: tp.key, value: tp.value } },
              )
            when :basic_authorization
              data.merge!(
                username: record.username,
                password: record.password,
              )
            end
          end

          data
        end

        def fill_authorization_from_data(record, data)
          type = record._type.split('::').last.underscore

          case type.to_sym
          when :oauth2_authorization
            item = { identifier: data[:client_id], secret: data[:client_secret] }
            record.client.from_json(item, add_only: true)
            record.client.save!

            item = { authorization_endpoint: data[:auth_url], token_endpoint: data[:access_token_url] }
            record.client.provider.from_json(item, add_only: true)
            record.client.provider.save!

            item = { parameters: data[:parameters], template_parameters: data[:template_parameters] }
            record.from_json(item, ignore: %i[client], reset: true)
            record.save!
          when :basic_authorization
            record.username = data[:username]
            record.password = data[:password]
          end
        end

        def authorization_params(action)
          raise('[400] - Service not available') if action != :update

          parameters = params.permit(data: {}).to_h

          check_attr_validity(:data, nil, parameters, true, Hash)

          data = parameters[:data]
          data[:id] = params[:id]

          type = @record._type.split('::').last.underscore

          case type.to_sym
          when :oauth2_authorization
            check_attr_validity(:auth_url, nil, data, true, String)
            check_attr_validity(:access_token_url, nil, data, true, String)
            check_attr_validity(:client_id, nil, data, true, String)
            check_attr_validity(:client_secret, nil, data, true, String)
            check_attr_validity(:scopes, nil, data, false, String)
            check_attr_validity(:parameters, nil, data, false, Array)
            check_attr_validity(:template_parameters, nil, data, false, Array)
          when :basic_authorization
            check_attr_validity(:username, nil, data, true, String)
            check_attr_validity(:password, nil, data, true, String)
          end

          data
        end
      end
    end
  end
end
