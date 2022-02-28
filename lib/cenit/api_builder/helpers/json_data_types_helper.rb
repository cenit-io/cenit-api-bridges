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

        def parse_from_params_to_selection_json_data_types_criteria
          exp_term = { '$regex' => ".*#{params[:term]}.*", '$options' => 'i' }
          terms_conditions = [{ namespace: exp_term }, { name: exp_term }, { title: exp_term }]
          { '$or' => terms_conditions }
        end

        def json_data_type_params(action)
          raise "TODO: The '#{action}' action is still under construction."
        end
      end
    end
  end
end
