require 'cenit/api_bridges/models/service'

module Cenit
  module ApiBridges
    document_type :Bridge do
      field :position, type: Integer, default: 0
      field :active, type: Mongoid::Boolean, default: false

      embeds_one :listen, class_name: Service.name, inverse_of: nil
      embeds_one :target, class_name: Service.name, inverse_of: nil

      belongs_to :application, class_name: 'Cenit::ApiBridges::Application', inverse_of: :bridges
    end
  end
end