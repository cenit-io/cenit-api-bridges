# frozen_string_literal: true

require_relative "api_builder/version"

module Cenit
  module ApiBuilder
    include BuildInApps
    include OauthApp

    app_name 'Cenit API Builder'
    app_key 'api/builder'
    controller_prefix 'cenit/api_builder'

    oauth_authorization_for 'openid profile email offline_access session_access multi_tenant create read update delete digest'

    DEFAULT_CLOUD_URL = ENV['API_BUILDER_FRONTEND'] || 'https://cenit-api-builder.onrender.com'

    default_url DEFAULT_CLOUD_URL
  end
end

require 'cenit/api_builder/controllers/default_controller'
require 'cenit/api_builder/controllers/admin_controller'
require 'cenit/api_builder/models/bridging_service_application'
require 'cenit/api_builder/models/local_service_application'
require 'cenit/api_builder/routes'
