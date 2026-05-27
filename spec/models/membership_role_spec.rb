require "rails_helper"

RSpec.describe MembershipRole do
  it "requires the role and membership to belong to the same church" do
    membership = create(:church_membership)
    other_role = create(:role)
    membership_role = build(:membership_role, church_membership: membership, role: other_role)

    expect(membership_role).not_to be_valid
    expect(membership_role.errors[:role]).to include("must belong to the same church as the membership")
  end
end
