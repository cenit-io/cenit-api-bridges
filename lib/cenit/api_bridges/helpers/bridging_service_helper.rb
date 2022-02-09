module Cenit
  module ApiBridges
    module Helpers
      module BridgingServiceHelper
        def parse_from_record_to_response_bs(record)
          {
            id: record.id.to_s,
            listen: record.listen,
            target: record.target,
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

        def bs_params(action)
          parameters = params.permit(
            data: [
              listen: %i[method path],
              application: %i[id]
            ]
          ).to_h

          check_attr_validity(:data, nil, parameters, true, Hash)

          data = parameters[:data]

          if action == :update
            data[:id] = params[:id]
            check_allow_params(%i[listen], data)
          else
            check_allow_params(%i[listen application], data)
            check_allow_params(%i[id], data[:application])
          end
          check_allow_params(%i[method path], data[:listen])

          check_attr_validity(:namespace, nil, data, true, String)
          check_attr_validity(:listening_path, nil, data, true, String)

          data[:application][:_reference] = true

          parameters
        end
      end
    end
  end
end
