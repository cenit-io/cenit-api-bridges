# frozen_string_literal: true

RSpec.describe Cenit::ApiBuilder do
  version = Cenit::ApiBuilder::VERSION

  it "has a version number: #{version}" do
    expect(version).not_to be nil
  end
end
