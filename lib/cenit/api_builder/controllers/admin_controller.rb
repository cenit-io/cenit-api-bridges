require 'cenit/api_builder/helpers/admin_helper'
require 'cenit/api_builder/helpers/open_api_spec_helper'
require 'cenit/api_builder/helpers/bs_apps_helper'
require 'cenit/api_builder/helpers/ls_apps_helper'
require 'cenit/api_builder/helpers/bridging_service_helper'
require 'cenit/api_builder/helpers/local_service_helper'
require 'cenit/api_builder/helpers/connections_helper'
require 'cenit/api_builder/helpers/authorizations_helper'
require 'cenit/api_builder/helpers/json_data_types_helper'
require 'cenit/api_builder/helpers/webhooks_helper'
require 'cenit/api_builder/helpers/tenants_helper'

module Cenit
  module ApiBuilder
    controller do
      include Helpers::AdminHelper
      include Helpers::OpenApiSpecHelper
      include Helpers::BSAppHelper
      include Helpers::LSAppHelper
      include Helpers::BridgingServiceHelper
      include Helpers::LocalServiceHelper
      include Helpers::ConnectionsHelper
      include Helpers::AuthorizationsHelper
      include Helpers::JsonDataTypesHelper
      include Helpers::WebHooksHelper
      include Helpers::TenantsHelper

      before_action :find_authorize_account_by_id, only: %i[authorize]
      before_action :find_authorize_account_by_token, except: %i[cors_check authorize]
      before_action :find_data_type, except: %i[cors_check process_bridging_service process_local_service]
      before_action :find_record, only: %i[show update switch_tenant authorize]

      def index
        respond_with_records(@dt, params[:model])
      rescue StandardError => e
        respond_with_exception(e)
      end

      def show
        respond_with_record(@record, params[:model])
      rescue StandardError => e
        respond_with_exception(e)
      end

      def create
        data = parse_request_data(params[:model], :create)
        @record = @dt.create_from_json!(data, { primary_field: %i[id], add_only: false })

        if (params[:model].to_sym == :bs_apps)
          data = parse_request_data(params[:model], :update)
          fill_from_data(@record, data)
          @record.save!
        end

        respond_with_record(@record, params[:model])
      rescue StandardError => e
        respond_with_exception(e)
      end

      def update
        data = parse_request_data(params[:model], :update)
        fill_from_data(@record, data)
        @record.save!

        respond_with_record(@record, params[:model])
      rescue StandardError => e
        respond_with_exception(e)
      end

      def destroy
        ids = params[:item_ids] || [params[:id]]
        @dt.where(id: { '$in' => ids }).each(&:destroy)

        render json: { success: true }
      rescue StandardError => e
        respond_with_exception(e)
      end

      def toggle_state
        parameters = params.permit(item_ids: []).to_h

        check_attr_validity(:item_ids, nil, parameters, true, Array)

        @dt.where(id: { '$in' => parameters[:item_ids] }).each do |record|
          record.active = !record.active
          record.save!
        end

        render json: { success: true }
      rescue StandardError => e
        respond_with_exception(e)
      end

      def authorize
        fields = []
        spec = @record.spec

        spec.components.security_schemes.each do |_, security_scheme|
          next unless security_scheme.type == 'apiKey'

          tp_name = security_scheme.name.parameterize.underscore
          fields << { name: tp_name, label: security_scheme.name, description: security_scheme.description }
        end

        render :authorization_page, layout: 'authorization_layout', locals: { fields: fields }
      rescue StandardError => e
        respond_with_exception(e)
      end

    end
  end
end