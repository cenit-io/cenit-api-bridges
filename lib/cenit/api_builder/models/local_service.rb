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

      protected

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

        dt_name = schema_name_form_api_spec.parameterize.underscore.classify
        dt_data = { namespace: application.namespace, name: dt_name }
        api_schema = self.application.spec.components.schemas[schema_name_form_api_spec]

        self.target = Setup::JsonDataType.where(dt_data).first || Setup::JsonDataType.create_from_json!(
          dt_data.merge(
            title: api_schema.title || dt_name,
            code: parse_json_schema(api_schema).to_json
          )
        )

        self.save!
      end

      def schema_name_form_api_spec
        self.metadata.deep_symbolize_keys[:schema_name]
      end

      def parse_json_schema(api_schema)
        type = api_schema.type || 'object'

        json_schema = { type: type, description: api_schema.description }

        case type.to_sym
        when :object
          json_schema[:properties] = api_schema.properties.inject({}) do |p_json_schema, p_api_schema|
            name, schema = p_api_schema
            p_json_schema[name] = parse_json_schema(schema)
            p_json_schema
          end

          api_schema.all_of&.each { |schema| json_schema[:properties].merge!(parse_json_schema(schema)[:properties]) }
        when :array
          json_schema[:items] = parse_json_schema(api_schema.items)
        end

        json_schema
      end

    end
  end
end