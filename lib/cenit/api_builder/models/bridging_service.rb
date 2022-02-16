require 'cenit/api_builder/models/service'

module Cenit
  module ApiBuilder
    document_type :BridgingService do
      field :position, type: Integer, default: 0
      field :active, type: Mongoid::Boolean, default: false

      embeds_one :listen, class_name: Service.name, inverse_of: nil
      embeds_one :target, class_name: Service.name, inverse_of: nil
      belongs_to :webhook, class_name: Setup::PlainWebhook.name, inverse_of: nil
      belongs_to :application, class_name: 'Cenit::ApiBuilder::BridgingServiceApplication', inverse_of: :services

      validates_presence_of :listen, :target, :application
      validate :unique_listen_validation

      before_save :transform_listen_path
      before_destroy :destroy_webhook
      after_save :setup_webhook

      def unique_listen_validation
        criteria = {
          'id' => { '$nin' => [self.id.to_s] },
          'application' => self.application,
          'listen.path' => self.listen.path,
          'listen.method' => self.listen.method,
        }
        errors.add(:listen, "already exist") unless self.class.where(criteria).first.nil?
      end

      def transform_listen_path
        self.listen.path = self.listen.path.gsub(/\{([^\}]+)\}/, ':\1')
      end

      def setup_webhook()
        return if self.webhook.present? || !self.active

        spec = application.spec
        path = target.path
        method = target.method
        service_spec = spec[:paths][path.to_sym][method.to_sym]

        wh_template_parameters = path.scan(/\{([^\}]+)\}/).flatten.map { |n| { key: n, value: '-' } }
        wh_path = path.gsub(/\{([^\}]+)\}/, '{{\1}}')
        wh_data = {
          namespace: application.namespace,
          name: service_spec[:operationId] || "#{method}_#{path.parameterize.underscore}",
          method: method,
          path: wh_path,
          description: "#{service_spec[:summary]}\n\n#{service_spec[:description]}".strip,
          template_parameters: wh_template_parameters
        }

        self.webhook = Setup::PlainWebhook.create_from_json!(wh_data)

        save!
      end

      def destroy_webhook
        self.webhook.try(:destroy)
      end
    end
  end
end