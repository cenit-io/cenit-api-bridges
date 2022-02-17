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
    end
  end
end
