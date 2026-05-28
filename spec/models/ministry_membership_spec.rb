require "rails_helper"

RSpec.describe MinistryMembership do
  it "requires the member to belong to the ministry church" do
    ministry = create(:ministry)
    other_member = create(:member)
    ministry_membership = build(:ministry_membership, ministry:, member: other_member)

    expect(ministry_membership).not_to be_valid
    expect(ministry_membership.errors[:member]).to include("must belong to the same church as the ministry")
  end

  it "keeps a member assigned once per ministry" do
    ministry = create(:ministry)
    member = create(:member, church: ministry.church)
    create(:ministry_membership, ministry:, member:)
    duplicate = build(:ministry_membership, ministry:, member:)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:member_id]).to be_present
  end
end
