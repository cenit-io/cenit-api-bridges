require 'cenit/api_bridges/models/service'

module Cenit
  module ApiBridges
    document_type :BridgingService do
      field :position, type: Integer, default: 0
      field :active, type: Mongoid::Boolean, default: false

      embeds_one :listen, class_name: Service.name, inverse_of: nil
      embeds_one :target, class_name: Service.name, inverse_of: nil
      belongs_to :webhook, class_name: Setup::PlainWebhook.name, inverse_of: nil
      belongs_to :application, class_name: 'Cenit::ApiBridges::BridgingServiceApplication', inverse_of: :services

      validates_presence_of :listen, :target, :application

      before_destroy :destroy_webhook

      def destroy_webhook
        self.webhook.try(:destroy)
      end
    end
  end
end