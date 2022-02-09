module Cenit
  module ApiBuilder

    controller do

      get '/' do
        default_oauth_callback_uri = "#{::Cenit.homepage}#{::Cenit.oauth_path}/callback"
        @uris = uris = (redirect_uris - [default_oauth_callback_uri]).map do |uri|
          uri = URI.parse(uri)
          new_query_ar = URI.decode_www_form(String(uri.query)) << ['cenitHost', Cenit.homepage]
          uri.query = URI.encode_www_form(new_query_ar)
          uri
        end
        if uris.length == 1
          redirect_to uris[0].to_s
        end
      end

    end

  end
end