require 'openapi3_parser'
require 'cenit/api_builder/models/local_service'

module Cenit
  module ApiBuilder
    document_type :LocalServiceApplication do
      field :namespace, type: String
      field :listening_path, type: String

      belongs_to :specification, class_name: Setup::ApiSpec.name, inverse_of: nil

      has_many :services, class_name: LocalService.name, inverse_of: :application

      validates_presence_of :namespace, :listening_path, :specification

      validates_length_of :namespace, minimum: 3, maximum: 15
      validates_length_of :listening_path, minimum: 3, maximum: 15

      validates_format_of :namespace, with: /\A[a-z][a-z0-9]*\Z/i
      validates_format_of :listening_path, with: /\A[a-z0-9]+([_-][a-z0-9]+)*\Z/

      validates_uniqueness_of :listening_path, scope: :namespace

      after_save :setup_services
      before_destroy :destroy_services

      def spec
        @spec ||= begin
          api_spec = Psych.load(self.specification.specification)
          api_spec.delete('swagger')
          Openapi3Parser.load(api_spec)
        end
      end

      def eligible_api_schema?(api_schema)
        return false if api_schema.one_of || api_schema.any_of || api_schema.not

        type = api_schema.type || 'object'

        case type.to_sym
        when :object
          return false if api_schema.properties.detect { |_, schema| !eligible_api_schema?(schema) }
        when :array
          return eligible_api_schema?(api_schema.items)
        end

        true
      end

      def setup_services
        return unless services.count == 0

        priority = 0
        spec.components.schemas.keys.each do |name|
          next unless eligible_api_schema?(spec.components.schemas[name])

          setup_service(name, "#{name}", 'get', priority)
          setup_service(name, "#{name}", 'post', priority)
          setup_service(name, "#{name}/:id", 'get', priority)
          setup_service(name, "#{name}/:id", 'post', priority)
          setup_service(name, "#{name}/:id", 'delete', priority)

          priority += 1
        end
      end

      def setup_service(schema_name, path, method, priority)
        service = Cenit::ApiBuilder::LocalService.new(
          priority: priority,
          active: false,
          listen: { method: method, path: path },
          metadata: { schema_name: schema_name },
          application: self,
        )
        service.save!
      end

      def destroy_services
        services.each(&:destroy)
      end
    end
  end
end
