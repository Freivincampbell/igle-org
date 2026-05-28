require "rails_helper"

RSpec.describe Ministry do
  it "requires a name" do
    ministry = build(:ministry, name: "")

    expect(ministry).not_to be_valid
    expect(ministry.errors[:name]).to be_present
  end

  it "keeps ministry names unique per church" do
    church = create(:church)
    create(:ministry, church:, name: "Alabanza")
    duplicate = build(:ministry, church:, name: "Alabanza")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:name]).to be_present
  end

  it "allows the same ministry name in different churches" do
    create(:ministry, name: "Alabanza")
    ministry = build(:ministry, name: "Alabanza")

    expect(ministry).to be_valid
  end
end
