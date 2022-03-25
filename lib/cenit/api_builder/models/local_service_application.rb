require 'cenit/api_builder/models/open_api_spec'
require 'cenit/api_builder/models/local_service'
require 'cenit/api_builder/models/common_service_application'

module Cenit
  module ApiBuilder
    document_type :LocalServiceApplication do
      include CommonServiceApplication

      has_many :services, class_name: LocalService.name, inverse_of: :application

      validates_presence_of :namespace, :listening_path, :specification

      after_save :setup_access_token, :setup_services

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

          setup_service(name, "#{name}", 'get', priority, 'Get items list')
          setup_service(name, "#{name}", 'post', priority, 'Create a new item')
          setup_service(name, "#{name}/:id", 'get', priority, 'Get an item by id')
          setup_service(name, "#{name}/:id", 'put', priority, 'Update an item')
          setup_service(name, "#{name}/:id", 'delete', priority, 'Delete an item')

          priority += 1
        end
      end

      def setup_service(schema_name, path, method, priority, description)
        service = Cenit::ApiBuilder::LocalService.new(
          priority: priority,
          active: false,
          listen: { method: method, path: path },
          metadata: { schema_name: schema_name },
          description: description,
          application: self,
        )
        service.save!
      end
    end
  end
end
