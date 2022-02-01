# frozen_string_literal: true

RSpec.describe Cenit::ApiBridges do
  version = Cenit::ApiBridges::VERSION

  it "has a version number: #{version}" do
    expect(version).not_to be nil
  end
end
