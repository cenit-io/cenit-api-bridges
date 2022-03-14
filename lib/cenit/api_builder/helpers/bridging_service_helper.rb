module Cenit
  module ApiBuilder
    module Helpers
      module BridgingServiceHelper
        def parse_from_record_to_response_bridging_service(record, with_details = false)
          {
            id: record.id.to_s,
            listen: parse_from_record_to_response_bs_listen(record.listen),
            target: parse_from_record_to_response_bs_target(record.target),
            active: record.active,
            priority: record.priority,
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

        def parse_from_record_to_response_bs_listen(record)
          {
            path: record.path,
            method: record.method,
          }
        end

        def parse_from_record_to_response_bs_target(record)
          return nil unless record

          {
            path: record.path,
            method: record.method,
          }
        end

        def parse_from_params_to_selection_bridging_services_criteria
          exp_term = { '$regex' => ".*#{params[:term]}.*", '$options' => 'i' }

          terms_conditions = [
            { 'listen.method' => exp_term },
            { 'listen.path' => exp_term }
          ]

          unless params[:app_id].present?
            app_ids = Cenit::ApiBuilder::BridgingServiceApplication.where(namespace: exp_term).map(&:id)
            terms_conditions << { 'application_id' => { '$in' => app_ids } }
          end

          criteria = []
          criteria << { application_id: params[:app_id] } if params[:app_id].present?
          criteria << { '$or' => terms_conditions } if params[:term].present?

          criteria.any? ? { '$and' => criteria } : {}
        end

        def bridging_service_params(action)
          raise('[400] - Service not available') if action != :update

          parameters = params.permit(data: [listen: %i[method path]]).to_h

          check_attr_validity(:data, nil, parameters, true, Hash)

          data = parameters[:data]

          check_allow_params(%i[listen], data)
          check_allow_params(%i[method path], data[:listen])

          check_attr_validity(:method, 'data[listen]', data[:listen], true, String)
          check_attr_validity(:path, 'data[listen]', data[:listen], true, String)

          data[:id] = params[:id]
          data
        end

        def process_bridging_service
          raise '[400] - This services is under constructions'
        rescue StandardError => e
          respond_with_exception(e)
        end
      end
    end
  end
end
