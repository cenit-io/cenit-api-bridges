# frozen_string_literal: true

RSpec.describe Cenit::ApiGateways do
  version = Cenit::ApiGateways::VERSION

  it "has a version number: #{version}" do
    expect(version).not_to be nil
  end
end
