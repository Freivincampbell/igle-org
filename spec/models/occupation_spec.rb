require "rails_helper"

RSpec.describe Occupation do
  describe "validations" do
    it "requires church and name" do
      o = Occupation.new
      o.valid?
      expect(o.errors).to include(:church, :name)
    end

    it "scopes uniqueness by church" do
      church = create(:church)
      create(:occupation, church:, name: "Doctor")
      duplicate = build(:occupation, church:, name: "doctor")

      expect(duplicate).not_to be_valid
    end

    it "allows same name in different churches" do
      create(:occupation, church: create(:church), name: "Doctor")
      other = build(:occupation, church: create(:church), name: "Doctor")

      expect(other).to be_valid
    end
  end
end
