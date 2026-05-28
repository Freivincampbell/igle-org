require "rails_helper"

RSpec.describe Ministries::MemberAssignment do
  describe "#save" do
    it "assigns active church members using public identifiers" do
      church = create(:church)
      ministry = create(:ministry, church:)
      member = create(:member, church:)

      assignment = described_class.new(
        ministry:,
        member_public_ids: [ member.public_id ],
        member_roles: { member.public_id => "leader" }
      )

      expect(assignment.save).to be(true)
      expect(ministry.ministry_memberships.active.count).to eq(1)
      expect(ministry.ministry_memberships.first).to be_leader
    end

    it "rejects members from another church" do
      ministry = create(:ministry)
      other_member = create(:member)

      assignment = described_class.new(
        ministry:,
        member_public_ids: [ other_member.public_id ],
        member_roles: { other_member.public_id => "member" }
      )

      expect(assignment.save).to be(false)
      expect(ministry.ministry_memberships).to be_empty
    end

    it "inactivates members removed from the assignment" do
      church = create(:church)
      ministry = create(:ministry, church:)
      member = create(:member, church:)
      ministry_membership = create(:ministry_membership, ministry:, member:)

      assignment = described_class.new(ministry:, member_public_ids: [], member_roles: {})

      expect(assignment.save).to be(true)
      expect(ministry_membership.reload).to be_inactive
    end
  end
end
