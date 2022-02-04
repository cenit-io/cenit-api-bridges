require 'cenit/api_bridges/models/bridge'

module Cenit
  module ApiBridges
    document_type :Application, multi_tenant: true do
      field :name, type: String
      field :base_path, type: String
      field :target_api_base_url, type: String

      belongs_to :specification, class_name: Setup::ApiSpec.name, inverse_of: nil
      belongs_to :connection, class_name: Setup::Connection.name, inverse_of: nil
      belongs_to :authorization, class_name: Setup::Authorization.name, inverse_of: nil

      has_many :bridges, class_name: 'Cenit::ApiBridges::Bridge', inverse_of: :application

      build_in_data_type.referenced_by(:name, :base_path)

      validates_presence_of :name, :base_path, :target_api_base_url, :specification
      validates_length_of :name, minimum: 3, maximum: 15
      validates_length_of :base_path, minimum: 3, maximum: 15

      after_save :setup_connection
      before_destroy :destroy_connection

      def setup_connection
        return if target_api_base_url == self.connection.try(:url)

        current_connection = self.connection

        criteria = { namespace: 'ApiBridges', name: "connection_#{self.id.to_s}" }
        self.connection ||= Setup::Connection.where(criteria).first || Setup::Connection.new(criteria)

        self.connection.url = self.target_api_base_url
        self.connection.save!

        save! if self.connection != current_connection
      end

      def destroy_connection
        connection.try(:destroy)
      end
    end
  end
end
