module Cenit
  module ApiBridges
    module Helpers
      module BSAppHelper
        def parse_from_record_to_response_bs_app(record)
          {
            id: record.id.to_s,
            namespace: record.namespace,
            listening_path: record.listening_path,
            target_api_base_url: record.target_api_base_url,

            specification: {
              id: record.specification.id.to_s,
              title: record.specification.title,
            },

            services: record.services.map { |service| parse_from_record_to_response_bs(service) },
            updated_at: parse_datetime(record.updated_at),
            created_at: parse_datetime(record.created_at),
          }
        end

        def parse_from_record_to_response_bs(service)
          {
            method: service.listen.method,
            path: service.listen.path,
            active: service.active
          }
        end

        def bs_app_params(action)
          parameters = params.permit(
            data: [
              :namespace, :listening_path, :target_api_base_url,
              :specification => [:id]
            ]
          ).to_h

          check_attr_validity(:data, nil, parameters, true, Hash)

          data = parameters[:data]

          if action == :update
            data[:id] = params[:id]
            check_allow_params(%i[listening_path target_api_base_url], data)
          else
            check_allow_params(%i[listening_path target_api_base_url namespace specification], data)
          end

          check_attr_validity(:namespace, nil, data, true, String)
          check_attr_validity(:listening_path, nil, data, true, String)
          check_attr_validity(:target_api_base_url, nil, data, true, String)
          check_attr_validity(:specification, nil, data, true, Hash)
          check_attr_validity(:id, 'specification', data[:specification], true, String)

          data[:specification][:_reference] = true

          parameters
        end
      end
    end
  end
end
