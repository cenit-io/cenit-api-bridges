require 'cenit/api_builder/helpers/admin_helper'
require 'cenit/api_builder/helpers/api_spec_helper'
require 'cenit/api_builder/helpers/bs_app_helper'
# require 'cenit/api_builder/helpers/ls_app_helper'
require 'cenit/api_builder/helpers/bridging_service_helper'

module Cenit
  module ApiBuilder
    controller do
      include Cenit::ApiBuilder::Helpers::AdminHelper
      include Cenit::ApiBuilder::Helpers::ApiSpecHelper
      include Cenit::ApiBuilder::Helpers::BSAppHelper
      # include Cenit::ApiBuilder::Helpers::LSAppHelper
      include Cenit::ApiBuilder::Helpers::BridgingServiceHelper

      before_action :find_authorize_account, except: %i[cors_check]
      before_action :find_data_type, except: %i[cors_check]
      before_action :find_record, only: %i[show update]

      route :get, '/admin/:model', to: :index
      route :get, '/admin/:model/:id', to: :show
      route :post, '/admin/:model', to: :create
      route :post, '/admin/:model/:id', to: :update
      route :delete, '/admin/:model', to: :destroy

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

        @record.fill_from(data, options)
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

    end
  end
end