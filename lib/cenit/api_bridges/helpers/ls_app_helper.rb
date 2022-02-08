module Cenit
  module ApiBridges
    module Helpers
      module LSAppHelper
        def parse_from_record_to_response_ls_app(record)
          {
            id: record.id.to_s,
            namespace: record.name,
            listening_path: record.listening_path,

            specification: {
              id: record.specification.id.to_s,
              title: record.specification.title,
            },

            services: record.services.map { |service| parse_from_record_to_response_ls(service) },
            updated_at: parse_datetime(record.updated_at),
            created_at: parse_datetime(record.created_at),
          }
        end

        def parse_from_record_to_response_ls(service)
          {
            method: service.listen.method,
            path: service.listen.path,
          }
        end

        def ls_app_params(action)
          parameters = params.permit(data: [:name, :listening_path, specification: [:id]]).to_h

          check_attr_validity(:data, nil, parameters, true, Hash)

          parameters[:data][:id] = params[:id] if action == :update

          check_attr_validity(:name, nil, parameters[:data], true, String)
          check_attr_validity(:listening_path, nil, parameters[:data], true, String)
          check_attr_validity(:specification, nil, parameters[:data], true, Hash)
          check_attr_validity(:id, 'specification', parameters[:data][:specification], true, String)

          parameters
        end
      end
    end
  end
end
