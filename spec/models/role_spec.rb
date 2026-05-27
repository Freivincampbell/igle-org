require "rails_helper"

RSpec.describe Role do
  it "keeps role names unique inside each church" do
    church = create(:church)

    create(:role, church:, name: "Lider")
    duplicate = build(:role, church:, name: "Lider")

    expect(duplicate).not_to be_valid
  end
end
