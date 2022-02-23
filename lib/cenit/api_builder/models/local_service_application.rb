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
        @spec ||= Psych.load(self.specification.specification).deep_symbolize_keys
      end

      def setup_services
        return unless services.count == 0

        priority = 0
        spec[:components][:schemas].keys.each do |name|
          schema = spec[:components][:schemas][name]
          schema[:name] ||= name.to_s

          setup_service(schema, "#{name}", 'get', priority)
          setup_service(schema, "#{name}", 'post', priority)
          setup_service(schema, "#{name}/:id", 'get', priority)
          setup_service(schema, "#{name}/:id", 'post', priority)
          setup_service(schema, "#{name}/:id", 'delete', priority)

          priority += 1
        end
      end

      def setup_service(spec, path, method, priority)
        service = Cenit::ApiBuilder::LocalService.new(
          priority: priority,
          active: false,
          listen: { method: method, path: path },
          metadata: spec,
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
