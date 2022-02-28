require 'openapi3_parser'

module Cenit
  module ApiBuilder
    document_type :OpenApiSpec do
      field :title, type: String
      field :specification, type: String

      validates_presence_of :specification
      validate :validate_specification

      before_save :parse_title
      before_destroy :check_apps

      def spec
        @spec ||= Openapi3Parser.load(specification)
        @spec
      end

      def parse_title
        self.title = spec.info.title if title.blank?
      end

      def validate_specification
        errors.add(:specification, 'in not valid') unless spec.valid?
      end

      def check_apps
        criteria = { specification_id: self.id }
        apps = LocalServiceApplication.where(criteria).count + BridgingServiceApplication.where(criteria).count
        raise 'The spec cannot be deleted because it is being used in some applications' if apps != 0
      end
    end
  end
end