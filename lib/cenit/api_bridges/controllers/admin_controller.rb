require 'cenit/api_bridges/helpers/admin_helper'
require 'cenit/api_bridges/helpers/api_spec_helper'

module Cenit
  module ApiBridges

    controller do
      include Cenit::ApiBridges::Helpers::AdminHelper
      include Cenit::ApiBridges::Helpers::ApiSpecHelper

      before_action :find_authorize_account, except: %i[cors_check]
      before_action :find_data_type, except: %i[cors_check]
      before_action :find_record, only: %i[handle_admin_model_id]

      get '/admin/:model' do
        criteria = {}

        respond_with_records(@dt, criteria, params[:model])
      rescue StandardError => e
        respond_with_exception(e)
      end

      get '/admin/:model/:id' do
        respond_with_record(@record, params[:model])
      rescue StandardError => e
        respond_with_exception(e)
      end

      delete '/admin/:model' do
        ids = params[:item_ids]
        @dt.where(id: { '$in' => ids }).each(&:destroy)

        render json: { success: true }
      rescue StandardError => e
        respond_with_exception(e)
      end

    end
  end
end