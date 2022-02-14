# frozen_string_literal: true

module Cenit
  module ApiBuilder
    controller do
      # Custom actions
      route :post, '/admin/:model/toggle', to: :toggle_state, model: /^(bs)$/

      # Common actions
      route :get, '/admin/:model', to: :index
      route :get, '/admin/:model/:id', to: :show
      route :post, '/admin/:model', to: :create
      route :post, '/admin/:model/:id', to: :update
      route :delete, '/admin/:model', to: :destroy
    end
  end
end
