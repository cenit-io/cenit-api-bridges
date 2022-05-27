module Cenit
  module ApiBuilder
    module Helpers
      module BSAppHelper
        def parse_from_record_to_response_bs_app(record, _with_details = false)
          {
            id: record.id.to_s,
            namespace: record.namespace,
            listening_path: record.listening_path,
            target_api_base_url: record.target_api_base_url,
            connection: { id: record.connection.id.to_s, name: record.connection.name },
            authorization: parse_from_record_to_response_authorization(record.get_authorization, true),

            specification: record.specification.try { |spec| { id: spec.id.to_s, title: spec.title } },
            services: record.services.map { |service| parse_from_record_to_response_bs_ref(service) },
            updated_at: parse_datetime(record.updated_at),
            created_at: parse_datetime(record.created_at)
          }
        end

        def parse_from_record_to_response_bs_ref(service)
          {
            id: service.id.to_s,
            listen: service.listen,
            active: service.active
          }
        end

        def parse_from_params_to_selection_bs_apps_criteria
          exp_term = { '$regex' => ".*#{params[:term]}.*", '$options' => 'i' }
          terms_conditions = [{ namespace: exp_term }, { 'listening_path': exp_term }]
          { '$and' => [{ '$or' => terms_conditions }] }
        end

        def fill_bs_app_from_data(record, data)
          auth = record.get_authorization
          auth_data = data.delete(:authorization)
          type = auth._type.split('::').last.underscore

          case type.to_sym
          when :oauth2_authorization
            auth.client.update(identifier: auth_data[:client_id], secret: auth_data[:client_secret])
            auth.client.provider.update(authorization_endpoint: auth_data[:auth_url], token_endpoint: auth_data[:access_token_url])

            scopes = auth.template_parameters.detect { |tp| tp.key == 'scopes' } || begin
              auth.from_json({ template_parameters: [{ key: 'scopes' }] }, add_only: true)
              auth.template_parameters.last
            end
            scopes.update(value: auth_data[:scopes])
          when :basic_authorization
            auth.update(auth_data)
          end

          record.from_json(data, add_only: true)
          record.save!
        end

        def bs_app_params(action)
          parameters = params.permit(data: {}).to_h

          check_attr_validity(:data, nil, parameters, true, Hash)

          data = parameters[:data]
          allow_params = %i[listening_path target_api_base_url]

          if action == :create
            allow_params += %i[namespace specification]
            check_allow_params(allow_params, data)
            check_attr_validity(:namespace, nil, data, true, String)
            check_attr_validity(:specification, nil, data, true, Hash)
            check_attr_validity(:id, 'specification', data[:specification], true, String)
            data[:specification][:_reference] = true
          else
            allow_params += %i[authorization]
            check_allow_params(allow_params, data)
            check_attr_validity(:authorization, nil, data, true, Hash)

            type = @record.get_authorization._type.split('::').last.underscore
            scope = data[:authorization]
            scope_name = 'data.authorization'

            case type.to_sym
            when :oauth2_authorization
              allow_params = %i[auth_url access_token_url client_id client_secret scopes]
              check_allow_params(allow_params, scope)

              check_attr_validity(:auth_url, scope_name, scope, true, String)
              check_attr_validity(:access_token_url, scope_name, scope, true, String)
              check_attr_validity(:client_id, scope_name, scope, true, String)
              check_attr_validity(:client_secret, scope_name, scope, true, String)
              check_attr_validity(:scopes, scope_name, scope, false, String)
            when :basic_authorization
              allow_params = %i[username password]
              check_allow_params(allow_params, scope)

              check_attr_validity(:username, scope_name, scope, true, String)
              check_attr_validity(:password, scope_name, scope, true, String)
            end

            data[:id] = @record.id
          end

          check_attr_validity(:listening_path, nil, data, true, String)
          check_attr_validity(:target_api_base_url, nil, data, false, String)

          data
        end
      end
    end
  end
end
