module Cenit
  module ApiBuilder
    module Helpers
      module TenantsHelper
        def parse_from_record_to_response_tenant(record, with_details = false)
          {
            id: record.id.to_s,
            name: record.name,
            locked: record.locked,
            notification_level: record.notification_level,
            owner: {
              id: record.owner.id.to_s,
              name: record.owner.name,
              email: record.owner.email,
            },
            updated_at: parse_datetime(record.updated_at),
            created_at: parse_datetime(record.created_at),
          }
        end

        def parse_from_params_to_selection_tenants_criteria
          exp_term = { '$regex' => ".*#{params[:term]}.*", '$options' => 'i' }
          terms_conditions = [{ name: exp_term }]
          { '$or' => terms_conditions }
        end

        def tenant_params(action)
          raise "TODO: The '#{action}' action is still under construction."
        end

        def switch_tenant
          # @access_token.tenant = @record
          # @access_token.save!
          # @access_token.set_current_tenant!
          # Account.current = @record
          User.current.account = @record
          User.current.save!
          # find_authorize_account
          render json: { success: true }
        end
      end
    end
  end
end
