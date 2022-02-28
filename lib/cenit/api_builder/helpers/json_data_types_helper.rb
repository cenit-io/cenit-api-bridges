module Cenit
  module ApiBuilder
    module Helpers
      module JsonDataTypesHelper
        def parse_from_record_to_response_json_data_type(record)
          {
            id: record.id.to_s,
            namespace: record.namespace,
            name: record.name,
            title: record.title,
            schema: record.code,
            updated_at: parse_datetime(record.updated_at),
            created_at: parse_datetime(record.created_at),
          }
        end

        def json_data_types_params(action)
        end
      end
    end
  end
end
