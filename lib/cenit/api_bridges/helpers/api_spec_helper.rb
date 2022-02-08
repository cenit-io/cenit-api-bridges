module Cenit
  module ApiBridges
    module Helpers
      module ApiSpecHelper

        def paths

        end

        def parse_from_record_to_response_api_spec(record)
          specification = Psych.load(record.specification).deep_symbolize_keys
          {
            id: record.id.to_s,
            title: record.title,
            version: specification[:info][:version],
            specification: record.specification,
            updated_at: parse_datetime(record.updated_at),
            created_at: parse_datetime(record.created_at),
          }
        end

        def api_spec_params(action)
          parameters = params.permit(data: %i[title specification]).to_h

          check_attr_validity(:data, nil, parameters, true, Hash)

          parameters[:data][:id] = params[:id] if action == :update

          check_attr_validity(:title, nil, parameters[:data], true, String)
          check_attr_validity(:specification, nil, parameters[:data], true, String)

          parameters
        end
      end
    end
  end
end
