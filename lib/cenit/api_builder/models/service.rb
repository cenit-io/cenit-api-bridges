module Cenit
  module ApiBuilder
    document_type :Service do
      field :method, type: String
      field :path, type: String

      validates_presence_of :method, :path
      validates_uniqueness_of :path, scope: :method

      def method_enum
        %w[get post put delete]
      end
    end
  end
end
