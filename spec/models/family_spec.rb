require "rails_helper"

RSpec.describe Family do
  describe "validations" do
    it "requires church and name" do
      family = Family.new

      family.valid?

      expect(family.errors).to include(:church, :name)
    end
  end

  describe "multi-tenant isolation" do
    it "scopes families to the church" do
      church_a = create(:church)
      church_b = create(:church)
      family_a = create(:family, church: church_a)
      family_b = create(:family, church: church_b)

      expect(church_a.families).to include(family_a)
      expect(church_a.families).not_to include(family_b)
    end
  end
end
