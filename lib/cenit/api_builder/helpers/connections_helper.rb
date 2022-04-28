module Cenit
  module ApiBuilder
    module Helpers
      module ConnectionsHelper
        def parse_from_record_to_response_connection(record, with_details = false)
          {
            id: record.id.to_s,
            namespace: record.namespace,
            name: record.name,
            url: record.url,
            authorization: record.authorization.try { |auth| { id: auth.id.to_s, name: auth.name } },
            headers: record.headers.map { |item| { key: item.key, value: item.value } },
            parameters: record.parameters.map { |item| { key: item.key, value: item.value } },
            template_parameters: record.template_parameters.map { |item| { key: item.key, value: item.value } },
            updated_at: parse_datetime(record.updated_at),
            created_at: parse_datetime(record.created_at),
          }
        end

        def connection_params(action)
          raise('[400] - Service not available') if action != :update

          parameters = params.permit(data: {}).to_h

          check_attr_validity(:data, nil, parameters, true, Hash)

          data = parameters[:data]

          check_allow_params(%i[name url headers parameters], data)
          data[:id] = params[:id]

          check_attr_validity(:name, nil, data, true, /^[a-z0-9]+(_[a-z0-9]+)*$/)
          check_attr_validity(:url, nil, data, true, /^http(s)?:\/\/([\w-]+\.)+[a-z]{2,3}(\/.*)*$/)
          check_attr_validity(:headers, nil, data, true, Array)
          check_attr_validity(:parameters, nil, data, true, Array)

          data
        end
      end
    end
  end
end
