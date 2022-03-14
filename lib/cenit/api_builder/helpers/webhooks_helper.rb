module Cenit
  module ApiBuilder
    module Helpers
      module WebHooksHelper
        def parse_from_record_to_response_webhook(record, with_details = false)
          {
            id: record.id.to_s,
            namespace: record.namespace,
            name: record.name,
            method: record.method,
            path: record.path,
            description: record.description,
            headers: record.headers,
            parameters: record.parameters,
            template_parameters: record.template_parameters,
            updated_at: parse_datetime(record.updated_at),
            created_at: parse_datetime(record.created_at),
          }
        end

        def parse_from_params_to_selection_webhooks_criteria
          exp_term = { '$regex' => ".*#{params[:term]}.*", '$options' => 'i' }
          terms_conditions = [{ namespace: exp_term }, { name: exp_term }, { path: exp_term }, { method: exp_term }]
          { '$or' => terms_conditions }
        end

        def webhook_params(action)
          raise "TODO: The '#{action}' action is still under construction."
        end
      end
    end
  end
end
