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
          'id' => { '$nin' => [id.to_s] },
          'application' => application,
          'listen.path' => listen.path,
          'listen.method' => listen.method,
        }
        errors.add(:listen, 'already exist') unless self.class.where(criteria).first.nil?
      end

      def transform_listen_path
        listen.path = listen.path.gsub(/\{([^\}]+)\}/, ':\1')
      end

      def setup_target()
        return if target.present? || !active

        meta_data = metadata.deep_symbolize_keys
        path = meta_data[:path]
        method = meta_data[:method]
        service_spec = application.spec.paths[path][method]

        headers = parse_webhook_headers(application.spec.paths[path])
        headers.concat(parse_webhook_headers(service_spec))

        parameters = parse_webhook_parameters(application.spec.paths[path])
        parameters.concat(parse_webhook_parameters(service_spec))

        template_parameters = parse_webhook_template_parameters(application.spec.paths[path])
        template_parameters.concat(parse_webhook_template_parameters(service_spec))

        service_parameters = parse_service_parameters(application.spec.paths[path])
        service_parameters.concat(parse_service_parameters(service_spec))

        wh_path = path.gsub(/\{([^\}]+)\}/, '{{\1}}')
        wh_data = {
          namespace: application.namespace,
          name: service_spec.operation_id || "#{method}_#{path.parameterize.underscore}",
          method: method,
          path: wh_path,
          description: "#{service_spec.summary}\n\n#{service_spec.description}".strip,
          headers: headers,
          parameters: parameters,
          template_parameters: template_parameters,
          metadata: meta_data.merge(service_parameters: service_parameters)
        }

        self.target = Setup::PlainWebhook.create_from_json!(wh_data)
        save!
      end

      def parse_webhook_parameters(service_spec)
        service_spec.parameters.select { |p| p.in == 'query' }.map do |p|
          { key: p.name, value: "{{#{p.name}}}" }
        end
      end

      def parse_webhook_template_parameters(service_spec)
        service_spec.parameters.map do |p|
          { key: p.name, value: p.schema.example ? JSON.generate(p.schema.example) : '' }
        end
      end

      def parse_webhook_headers(service_spec)
        service_spec.parameters.select { |p| p.in == 'header' }.map do |p|
          { key: p.name, value: "{{#{p.name}}}" }
        end
      end

      def parse_service_parameters(service_spec)
        service_spec.parameters.map do |p|
          {
            name: p.name,
            type: p.schema.type,
            in: p.in,
            description: p.description || p.schema.description,
            required: p.required?
          }
        end
      end

      def destroy_target
        target.try(:destroy)
      end
    end
  end
end