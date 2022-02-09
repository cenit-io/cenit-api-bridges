module Cenit
  module ApiBuilder
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

          data = parameters[:data]
          data[:id] = params[:id] if action == :update

          check_attr_validity(:name, nil, data, true, String)
          check_attr_validity(:listening_path, nil, data, true, String)
          check_attr_validity(:specification, nil, data, true, Hash)
          check_attr_validity(:id, 'specification', data[:specification], true, String)

          data
        end
      end
    end
  end
end
