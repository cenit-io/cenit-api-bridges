module Cenit
  module ApiBuilder

    controller do

      get '/' do
        default_oauth_callback_uri = "#{::Cenit.homepage}#{::Cenit.oauth_path}/callback"
        @uris = redirect_uris - [default_oauth_callback_uri]
        redirect_to @uris[0].to_s if @uris.length == 1
      end

    end

  end
end