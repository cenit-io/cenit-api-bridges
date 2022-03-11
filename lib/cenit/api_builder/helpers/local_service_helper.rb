module Cenit
  module ApiBuilder
    module Helpers
      module LocalServiceHelper
        def parse_from_record_to_response_local_service(record)
          {
            id: record.id.to_s,
            listen: parse_from_record_to_response_ls_listen(record.listen),
            target: parse_from_record_to_response_ls_target(record.target),
            active: record.active,
            priority: record.priority,
            description: record.description,
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

        def parse_from_record_to_response_ls_listen(record)
          {
            path: record.path,
            method: record.method,
          }
        end

        def parse_from_record_to_response_ls_target(record)
          return nil unless record

          {
            namespace: record.namespace,
            name: record.name,
          }
        end

        def parse_from_params_to_selection_local_services_criteria
          exp_term = { '$regex' => ".*#{params[:term]}.*", '$options' => 'i' }

          terms_conditions = [
            { 'listen.method' => exp_term },
            { 'listen.path' => exp_term }
          ]

          unless params[:app_id].present?
            app_ids = Cenit::ApiBuilder::LocalServiceApplication.where(namespace: exp_term).map(&:id)
            terms_conditions << { 'application_id' => { '$in' => app_ids } }
          end

          criteria = []
          criteria << { application_id: params[:app_id] } if params[:app_id].present?
          criteria << { '$or' => terms_conditions } if params[:term].present?

          criteria.any? ? { '$and' => criteria } : {}
        end

        def local_service_params(action)
          raise('[400] - Service not available') if action != :update

          parameters = params.permit(data: [:priority, :description, listen: %i[method path]]).to_h

          check_attr_validity(:data, nil, parameters, true, Hash)

          data = parameters[:data]

          check_allow_params(%i[listen priority description], data)
          check_allow_params(%i[method path], data[:listen])

          check_attr_validity(:priority, 'data', data, true, Integer)
          check_attr_validity(:description, 'data', data, true, String)
          check_attr_validity(:method, 'data[listen]', data[:listen], true, String)
          check_attr_validity(:path, 'data[listen]', data[:listen], true, String)

          data[:id] = params[:id]
          data
        end

        def process_local_service
          method = request.method.downcase
          req_a_path = URI.decode(params[:app_listening_path])
          req_s_path = URI.decode(params[:service_listening_path])

          app = Cenit::ApiBuilder::LocalServiceApplication.where(listening_path: req_a_path).first

          return respond_with_exception('[404] - Application not found') unless app

          services = app.services.where('active' => true, 'listen.method' => method).order_by(priority: 'ASC')
          service = services.detect { |s| check_service_request(s.listen.path, req_s_path) }

          return respond_with_exception('[404] - Service not found') unless service

          @dt = service.target
          params.merge(@path_params)
          params[:model] = 'ls_request'

          if @path_params.has_key?(:id)
            find_record
            return nil unless @record
          end

          method = method.to_sym
          return create if method == :post
          return index if method == :get && @record.nil?
          return show if method == :get
          return update if method == :put
          return destroy if method == :delete

          respond_with_exception('[404] - Service not found')
        rescue StandardError => e
          respond_with_exception(e)
        end

      end
    end
  end
end
