module Cenit
  module ApiBuilder
    module Helpers
      module AuthorizationsHelper
        def parse_from_record_to_response_authorization(record, with_details = false)
          {
            id: record.id.to_s,
            namespace: record.namespace,
            name: record.name,
            type: record._type.split('::').last.underscore,
            template_parameters: parse_from_record_to_response_authorization_tps(record),
            authorized: record.authorized,
            url: "#{Cenit.homepage}/authorization/#{Tenant.current.id}/#{record.id}/authorize",
            updated_at: parse_datetime(record.updated_at),
            created_at: parse_datetime(record.created_at),
          }
        end

        def parse_from_record_to_response_authorization_tps(record)
          return nil unless record.respond_to?(:template_parameters)
          record.template_parameters.map { |item| { key: item.key, value: item.value } }
        end

        def authorization_params(action)
          raise('[400] - Service not available') if action != :update

          parameters = params.permit(data: {}).to_h

          check_attr_validity(:data, nil, parameters, true, Hash)

          data = parameters[:data]
          data[:id] = params[:id]

          check_allow_params(%i[name], data)
          check_attr_validity(:name, nil, data, true, /^[a-z0-9]+(_[a-z0-9]+)*$/)

          data
        end
      end
    end
  end
end
