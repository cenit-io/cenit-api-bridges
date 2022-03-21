# frozen_string_literal: true

module Cenit
  module ApiBuilder
    CREATE_CONSTRAIN = /api_spec|bs_apps|ls_apps/
    UPDATE_CONSTRAIN = /api_spec|bridging_services|local_services|bs_apps|ls_apps|connections|json_data_type|webhooks/
    DELETE_CONSTRAIN = /api_spec|bs_apps|ls_apps|json_data_type|webhooks/
    TOGGLE_CONSTRAIN = /bridging_services|local_services/

    controller do
      # Common actions
      route :get, '/admin/:model', to: :index
      route :get, '/admin/:model/:id', to: :show
      route :post, '/admin/:model', to: :create, model: CREATE_CONSTRAIN
      route :post, '/admin/:model/:id', to: :update, model: UPDATE_CONSTRAIN
      route :delete, '/admin/:model', to: :destroy, model: DELETE_CONSTRAIN

      # Custom actions
      route :put, '/admin/:model/toggle', to: :toggle_state, model: TOGGLE_CONSTRAIN
      route :get, '/admin/:model/:id/switch', to: :switch_tenant, model: /tenants/

      # User services actions
      route :all, '/bs/:app_listening_path/*service_listening_path', to: :process_bridging_service
      route :all, '/ls/:app_listening_path/*service_listening_path', to: :process_local_service
    end
  end
end
