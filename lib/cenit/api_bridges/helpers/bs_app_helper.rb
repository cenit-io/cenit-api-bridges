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
          }
        end

        def bs_app_params(action)
          parameters = params.permit(data: [
            :namespace, :listening_path, :target_api_base_url,
            :specification => [:id]]
          ).to_h

          check_attr_validity(:data, nil, parameters, true, Hash)

          parameters[:data][:id] = params[:id] if action == :update

          check_attr_validity(:namespace, nil, parameters[:data], true, String)
          check_attr_validity(:listening_path, nil, parameters[:data], true, String)
          check_attr_validity(:target_api_base_url, nil, parameters[:data], true, String)
          check_attr_validity(:specification, nil, parameters[:data], true, Hash)
          check_attr_validity(:id, 'specification', parameters[:data][:specification], true, String)

          parameters[:data][:specification][:_reference] = true

          parameters
        end
      end
    end
  end
end
