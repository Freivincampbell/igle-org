require "rails_helper"

RSpec.describe Permissions::MembershipRoleAssignment do
  describe "#save" do
    it "replaces membership roles using role public identifiers" do
      church = create(:church)
      membership = create(:church_membership, church:)
      old_role = create(:role, church:)
      new_role = create(:role, church:)

      create(:membership_role, church_membership: membership, role: old_role)

      assignment = described_class.new(
        church_membership: membership,
        role_public_ids: [ new_role.public_id ]
      )

      expect(assignment.save).to be(true)
      expect(membership.roles.reload).to contain_exactly(new_role)
    end

    it "rejects roles from another church" do
      membership = create(:church_membership)
      other_role = create(:role)
      assignment = described_class.new(
        church_membership: membership,
        role_public_ids: [ other_role.public_id ]
      )

      expect(assignment.save).to be(false)
      expect(membership.roles.reload).to be_empty
    end
  end
end
