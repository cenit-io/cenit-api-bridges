module Cenit
  module ApiBridges
    module Helpers
      module AdminHelper
        private

        def find_data_type
          dt_name = params[:model].classify
          @dt = Cenit.namespace(:Setup).data_type(dt_name)
          respond_with_exception('[400] - Invalid model') unless @dt
        end

        def find_record
          @record = @dt.where(id: params[:id]).first
          respond_with_exception('[404] - Not found') unless @record
        end

        def find_authorize_account
          token_type, token = request.headers['Authorization'].to_s.split(' ')

          if access_token = Cenit::OauthAccessToken.where(token_type: token_type.to_s, token: token.to_s).first
            User.current = access_token.user
            access_token.set_current_tenant!
          end

          render json: { error: 'Unauthorized' }, status: 403 unless access_token.try(:user)
        end

        def check_parameters
          fail('Invalid model') unless @dt
        end

        def respond_with_exception(ex)
          msg = ex.is_a?(String) ? ex : ex.message
          code = msg =~ /^\[(\d+)\]/ ? $1.to_i : 500
          data = { type: 'exception', error: msg.gsub(/^\[(\d+)\] - /, ''), code: code }

          Tenant.notify(message: msg, type: :error)

          render json: data, status: code
        end

        def respond_with_record(record, type = nil, with_details = true)
          type ||= record.class.data_type.name.underscore

          response = begin
            {
              type: type,
              data: begin
                if respond_to?(parse_method = "parse_from_record_to_response_#{type}")
                  send(parse_method, record, with_details)
                else
                  record.to_hash(include_id: true).deep_symbolize_keys
                end
              end
            }
          end

          respond_with_format(response)
        end

        def respond_with_records(dt, criteria, type = nil)
          type ||= dt.name.underscore

          offset = params[:offset].to_i
          limit = (params[:limit] || 10).to_i
          sort = params[:sort] || { created_at: 'DESC' }
          total = dt.where(criteria).count

          response = begin
            if params[:without_data].to_b
              { type: type, data: [], pagination: { offset: 0, limit: limit, total: total } }
            else
              {
                type: type,
                data: begin
                  dt.where(criteria).order_by(sort).skip(offset).limit(limit).to_a.map do |record|
                    if respond_to?(parse_method = "parse_from_record_to_response_#{type}")
                      send(parse_method, record, params[:with_details])
                    else
                      record.to_hash(include_id: true).deep_symbolize_keys
                    end
                  end
                end,
                pagination: { offset: offset, limit: limit, total: total }
              }
            end
          end

          respond_with_format(response)
        end

        def respond_with_format(response, format = nil, status = 200)
          format ||= params[:format]

          if format == 'yaml'
            render text: response.to_yaml, content_type: 'text/yaml'
          else
            render json: response, code: status
          end
        end

        def parse_datetime(value)
          return if value.nil?

          value = value.iso8601 if value.is_a?(Time)
          value = DateTime.parse(value) if value.is_a?(String)
          value.iso8601
        end
      end
    end
  end
end
