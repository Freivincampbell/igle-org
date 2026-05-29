require "rails_helper"

RSpec.describe Permission do
  it "includes reports as an assignable module" do
    expect(described_class::ASSIGNABLE_MODULE_KEYS).to include("reports")
  end

  it "reports is a valid module key" do
    permission = described_class.new(module_key: "reports", action_key: "read", name: "Reportes - Leer")
    expect(permission).to be_valid
  end
end
