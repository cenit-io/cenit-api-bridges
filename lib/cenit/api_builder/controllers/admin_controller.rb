require 'cenit/api_builder/helpers/admin_helper'
require 'cenit/api_builder/helpers/api_spec_helper'
require 'cenit/api_builder/helpers/bs_app_helper'
require 'cenit/api_builder/helpers/ls_app_helper'
require 'cenit/api_builder/helpers/bridging_service_helper'
require 'cenit/api_builder/helpers/connections_helper'

module Cenit
  module ApiBuilder
    controller do
      include Helpers::AdminHelper
      include Helpers::ApiSpecHelper
      include Helpers::BSAppHelper
      include Helpers::LSAppHelper
      include Helpers::BridgingServiceHelper
      include Helpers::ConnectionsHelper

      before_action :find_authorize_account, except: %i[cors_check]
      before_action :find_data_type, except: %i[cors_check]
      before_action :find_record, only: %i[show update]

      def index
        criteria = {}

        respond_with_records(@dt, criteria, params[:model])
      rescue StandardError => e
        respond_with_exception(e)
      end

      def show
        respond_with_record(@record, params[:model])
      rescue StandardError => e
        respond_with_exception(e)
      end

      def create
        data, options = parse_request_data(params[:model], :create)
        record = @dt.create_from_json!(data, options)

        respond_with_record(record, params[:model])
      rescue StandardError => e
        respond_with_exception(e)
      end

      def update
        data, options = parse_request_data(params[:model], :update)

        fill_from_data(@record, data)

        @record.save!

        respond_with_record(@record, params[:model])
      rescue StandardError => e
        respond_with_exception(e)
      end

      def destroy
        ids = params[:item_ids]
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
      end

    end
  end
end