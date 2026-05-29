require "rails_helper"

RSpec.describe ReportPolicy do
  let(:church) { create(:church) }

  def setup_role(action_key)
    membership = create(:church_membership, church:)
    role = create(:role, church:)
    perm = Permission.find_by(module_key: "reports", action_key:) ||
           create(:permission, module_key: "reports", action_key:, name: "Reportes - #{action_key}")
    create(:role_permission, role:, permission: perm)
    create(:membership_role, church_membership: membership, role:)
    membership
  end

  describe "#index? / #show?" do
    it "permite con reports/read" do
      membership = setup_role("read")
      Current.set(user: membership.user, church:, church_membership: membership) do
        expect(described_class.new(membership.user, nil).index?).to be(true)
        expect(described_class.new(membership.user, nil).show?).to be(true)
      end
    end

    it "deniega sin permiso" do
      membership = create(:church_membership, church:)
      Current.set(user: membership.user, church:, church_membership: membership) do
        expect(described_class.new(membership.user, nil).index?).to be(false)
      end
    end

    it "permite al owner" do
      membership = create(:church_membership, :owner, church:)
      Current.set(user: membership.user, church:, church_membership: membership) do
        expect(described_class.new(membership.user, nil).index?).to be(true)
      end
    end
  end

  describe "#export?" do
    it "permite con reports/manage" do
      membership = setup_role("manage")
      Current.set(user: membership.user, church:, church_membership: membership) do
        expect(described_class.new(membership.user, nil).export?).to be(true)
      end
    end

    it "deniega con solo reports/read" do
      membership = setup_role("read")
      Current.set(user: membership.user, church:, church_membership: membership) do
        expect(described_class.new(membership.user, nil).export?).to be(false)
      end
    end
  end
end
