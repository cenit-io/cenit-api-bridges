module Cenit
  module ApiBuilder
    document_type :Service do
      field :method, type: String
      field :path, type: String

      embedded_in :bridging_service, class_name: 'Cenit::ApiBuilder::BridgingService', inverse_of: :linten
      embedded_in :local_service, class_name: 'Cenit::ApiBuilder::BridgingService', inverse_of: :linten

      validates_presence_of :method, :path

      def method_enum
        %w[get post put delete]
      end
    end
  end
end
