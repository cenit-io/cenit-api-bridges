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
          raise('[400] - Service not available') if action != :update

          parameters = params.permit(data: {}).to_h

          check_attr_validity(:data, nil, parameters, true, Hash)

          data = parameters[:data]

          check_allow_params(%i[name description headers parameters template_parameters], data)

          data[:id] = params[:id]

          check_attr_validity(:name, nil, data, true, /^[a-z0-9]+(_[a-z0-9]+)*$/)
          check_attr_validity(:description, nil, data, true, String)
          check_attr_validity(:headers, nil, data, false, Array)
          check_attr_validity(:parameters, nil, data, false, Array)
          check_attr_validity(:template_parameters, nil, data, false, Array)

          data
        end
      end
    end
  end
end
