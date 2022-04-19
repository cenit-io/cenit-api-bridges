module Cenit
  module ApiBuilder
    module Helpers
      module BSAppHelper
        def parse_from_record_to_response_bs_app(record, with_details = false)
          {
            id: record.id.to_s,
            namespace: record.namespace,
            listening_path: record.listening_path,
            target_api_base_url: record.target_api_base_url,

            authorization_type: record.authorization_type,
            auth_url: record.auth_url,
            access_token_url: record.access_token_url,
            client_id: record.client_id,
            client_secret: record.client_secret,

            specification: record.specification.try do |spec|
              {
                id: spec.id.to_s,
                title: spec.title,
              }
            end,

            services: record.services.map { |service| parse_from_record_to_response_bs_ref(service) },
            updated_at: parse_datetime(record.updated_at),
            created_at: parse_datetime(record.created_at),
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

        def bs_app_params(action)
          parameters = params.permit(
            data: [
              :listening_path, :target_api_base_url,
              :auth_url, :access_token_url, :client_id, :client_secret,
              :username, :password,
              :namespace, :specification => [:id]
            ]
          ).to_h

          check_attr_validity(:data, nil, parameters, true, Hash)

          data = parameters[:data]
          allow_params = %i[listening_path target_api_base_url auth_url access_token_url client_id client_secret username password]

          if action == :update
            data.delete(:namespace)
            data.delete(:specification)
            check_allow_params(allow_params, data)
            data[:id] = params[:id]
          else
            allow_params += %i[namespace specification]
            check_allow_params(allow_params, data)
            check_attr_validity(:namespace, nil, data, true, String)
            check_attr_validity(:specification, nil, data, true, Hash)
            check_attr_validity(:id, 'specification', data[:specification], true, String)
            data[:specification][:_reference] = true
          end

          check_attr_validity(:listening_path, nil, data, true, String)
          check_attr_validity(:target_api_base_url, nil, data, false, String)
          check_attr_validity(:auth_url, nil, data, false, String)
          check_attr_validity(:access_token_url, nil, data, false, String)
          check_attr_validity(:client_id, nil, data, false, String)
          check_attr_validity(:client_secret, nil, data, false, String)
          check_attr_validity(:username, nil, data, false, String)
          check_attr_validity(:password, nil, data, false, String)

          data
        end
      end
    end
  end
end
