require 'cenit/api_builder/models/service'

module Cenit
  module ApiBuilder
    document_type :LocalService do
      field :priority, type: Integer, default: 0
      field :active, type: Mongoid::Boolean, default: false
      field :metadata, type: Hash, default: {}

      embeds_one :listen, class_name: Service.name, inverse_of: nil
      belongs_to :target, class_name: Setup::JsonDataType.name, inverse_of: nil
      belongs_to :application, class_name: 'Cenit::ApiBuilder::LocalServiceApplication', inverse_of: :services

      validates_presence_of :listen, :application
      validate :validate_listen_field

      before_save :transform_listen_path
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

      def setup_target
        return if self.target.present? || !self.active

        dt_spec = self.metadata.deep_symbolize_keys
        dt_name = dt_spec[:name].parameterize.underscore.classify
        dt_data = { namespace: application.namespace, name: dt_name }

        self.target = Setup::JsonDataType.where(dt_data).first || Setup::JsonDataType.create_from_json!(
          dt_data.merge(
            title: dt_spec[:title] || dt_name,
            code: parse_cenit_schema.to_json
          )
        )

        self.save!
      end

      def parse_cenit_schema
        schema = {
          type: 'object',
          properties: {
            name: { type: 'string' }
          }
        }

        schema
      end

    end
  end
end