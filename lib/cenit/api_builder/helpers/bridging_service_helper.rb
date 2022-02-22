module Cenit
  module ApiBuilder
    module Helpers
      module BridgingServiceHelper
        def parse_from_record_to_response_bs(record)
          {
            id: record.id.to_s,
            listen: parse_from_record_to_response_service(record.listen),
            target: parse_from_record_to_response_service(record.target),
            active: record.active,
            priority: record.priority,
            application: record.application.try do |app|
              {
                id: app.id,
                namespace: app.namespace,
                listening_path: app.listening_path,
              }
            end,

            updated_at: parse_datetime(record.updated_at),
            created_at: parse_datetime(record.created_at),
          }
        end

        def parse_from_record_to_response_service(record)
          {
            path: record.path,
            method: record.method,
          }
        end

        def bs_params(action)
          raise('[400] - Service not available') if action != :update

          parameters = params.permit(data: [listen: %i[method path]]).to_h

          check_attr_validity(:data, nil, parameters, true, Hash)

          data = parameters[:data]

          check_allow_params(%i[listen], data)
          check_allow_params(%i[method path], data[:listen])

          check_attr_validity(:method, 'data[listen]', data[:listen], true, String)
          check_attr_validity(:path, 'data[listen]', data[:listen], true, String)

          data[:id] = params[:id]
          data
        end
      end
    end
  end
end
