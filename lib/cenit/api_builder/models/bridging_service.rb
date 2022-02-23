require 'cenit/api_builder/models/service'

module Cenit
  module ApiBuilder
    document_type :BridgingService do
      field :priority, type: Integer, default: 0
      field :active, type: Mongoid::Boolean, default: false
      field :metadata, type: Hash, default: {}

      embeds_one :listen, class_name: Service.name, inverse_of: nil
      belongs_to :target, class_name: Setup::PlainWebhook.name, inverse_of: nil
      belongs_to :application, class_name: 'Cenit::ApiBuilder::BridgingServiceApplication', inverse_of: :services

      validates_presence_of :listen, :application
      validate :validate_listen_field

      before_save :transform_listen_path
      before_destroy :destroy_target
      after_save :setup_target

      def validate_listen_field
        # check unique
        criteria = {
          'id' => { '$nin' => [self.id.to_s] },
          'application' => self.application,
          'listen.path' => self.listen.path,
          'listen.method' => self.listen.method,
        }
        errors.add(:listen, 'already exist') unless self.class.where(criteria).first.nil?
      end

      def transform_listen_path
        self.listen.path = self.listen.path.gsub(/\{([^\}]+)\}/, ':\1')
      end

      def setup_target()
        return if self.target.present? || !self.active

        _metadata = self.metadata.deep_symbolize_keys

        path = _metadata[:path]
        method = _metadata[:method]
        service_spec = _metadata[:spec]

        wh_template_parameters = path.scan(/\{([^\}]+)\}/).flatten.map { |n| { key: n, value: '-' } }
        wh_path = path.gsub(/\{([^\}]+)\}/, '{{\1}}')
        wh_data = {
          namespace: application.namespace,
          name: service_spec[:operationId] || "#{method}_#{path.parameterize.underscore}",
          method: method,
          path: wh_path,
          description: "#{service_spec[:summary]}\n\n#{service_spec[:description]}".strip,
          template_parameters: wh_template_parameters,
          metadata: service_spec
        }

        self.target = Setup::PlainWebhook.create_from_json!(wh_data)
        self.save!
      end

      def destroy_target
        self.target.try(:destroy)
      end
    end
  end
end