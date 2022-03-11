# frozen_string_literal: true

module Cenit
  module ApiBuilder
    controller do
      # Common actions
      route :get, '/admin/:model', to: :index
      route :get, '/admin/:model/:id', to: :show
      route :post, '/admin/:model', to: :create
      route :post, '/admin/:model/:id', to: :update
      route :delete, '/admin/:model', to: :destroy

      # Custom actions
      route :put, '/admin/:model/toggle', to: :toggle_state, model: /(bridging|local)_services/

      # User services actions
      route :all, '/bs/:app_listening_path/*service_listening_path', to: :process_bridging_service
      route :all, '/ls/:app_listening_path/*service_listening_path', to: :process_local_service
    end
  end
end
