# frozen_string_literal: true

require_relative "api_bridges/version"

module Cenit
  module ApiBridges
    include BuildInApps
    include OauthApp

    app_name 'Cenit API Bridges'
    app_key 'api/bridges'
    controller_prefix 'cenit/api_bridges'

    oauth_authorization_for 'openid profile email offline_access session_access multi_tenant create read update delete digest'

    # DEFAULT_CLOUD_URL = ENV['API_BRIDGES_FRONTEND'] || 'https://cenit-io-api-bridges.onrender.com'
    DEFAULT_CLOUD_URL = ENV['API_BRIDGES_FRONTEND'] || 'http://localhost:1234'

    default_url DEFAULT_CLOUD_URL
  end
end

require 'cenit/api_bridges/controller'