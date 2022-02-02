module Cenit
  module ApiBridges
    module Helpers
      module ApiSpecHelper
        def parse_from_record_to_response_api_spec(record, with_details = false)
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
      end
    end
  end
end
