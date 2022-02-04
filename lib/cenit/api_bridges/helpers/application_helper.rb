module Cenit
  module ApiBridges
    module Helpers
      module ApplicationHelper
        def parse_from_record_to_response_application(record, with_details = false)
          {
            id: record.id.to_s,
            name: record.name,
            base_path: record.base_path,
            target_api_base_url: record.target_api_base_url,

            specification: {
              id: record.specification.id.to_s,
              title: record.specification.title,
            },

            bridges: record.bridges.map { |bridge| parse_from_record_to_response_bridge(bridge) },
            updated_at: parse_datetime(record.updated_at),
            created_at: parse_datetime(record.created_at),
          }
        end

        def parse_from_record_to_response_bridge(record, with_details = false)
          {
            method: record.method,
            path: record.path,
          }
        end

        def application_params(action)
          parameters = params.permit(data: [:name, :base_path, :target_api_base_url, specification: [:id]]).to_h

          check_attr_validity(:data, nil, parameters, true, Hash)

          parameters[:data][:id] = params[:id] if action == :update

          check_attr_validity(:name, nil, parameters[:data], true, String)
          check_attr_validity(:base_path, nil, parameters[:data], true, String)
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
