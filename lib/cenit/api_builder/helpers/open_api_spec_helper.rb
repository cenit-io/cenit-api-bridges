module Cenit
  module ApiBuilder
    module Helpers
      module OpenApiSpecHelper
        def parse_from_record_to_response_api_spec(record, with_details = false)
          {
            id: record.id.to_s,
            title: record.title,
            version: record.spec.info.version,
            specification: record.specification,
            updated_at: parse_datetime(record.updated_at),
            created_at: parse_datetime(record.created_at),
          }
        end

        def api_spec_params(action)
          parameters = params.permit(data: %i[specification]).to_h

          check_attr_validity(:data, nil, parameters, true, Hash)

          data = parameters[:data]
          data[:id] = params[:id] if action == :update

          check_attr_validity(:specification, nil, data, true, String)

          data
        end
      end
    end
  end
end
