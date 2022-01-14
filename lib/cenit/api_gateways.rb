# frozen_string_literal: true

require_relative "api_gateways/version"

module Cenit
  module ApiGateways
    include BuildInApps
    include OauthApp

    app_name 'Cenit API Gateways'
    app_key 'api/gateways'
    controller_prefix 'cenit/api_gateways'

    oauth_authorization_for 'openid profile email session_access multi_tenant create read update delete digest'

    DEFAULT_CLOUD_URL = ENV['CONFIRMATION_REQUIRED'] || 'https://cenit-io-api-gateways.onrender.com'

    default_url DEFAULT_CLOUD_URL
  end
end

require 'cenit/api_gateways/controller'