module Cenit
  module ApiBuilder
    document_type :Service do
      field :method, type: String
      field :path, type: String

      def method_enum
        %w[GET POST PUT DELETE]
      end
    end
  end
end
