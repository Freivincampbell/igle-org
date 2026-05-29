require "rails_helper"

RSpec.describe MinistryPolicy do
  describe "#update?" do
    it "allows an owner inside the current church" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)
      ministry = create(:ministry, church:)

      Current.set(user: membership.user, church:, church_membership: membership) do
        expect(described_class.new(membership.user, ministry).update?).to be(true)
      end
    end

    it "denies a ministry from another church" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)
      other_ministry = create(:ministry)

      Current.set(user: membership.user, church:, church_membership: membership) do
        expect(described_class.new(membership.user, other_ministry).update?).to be(false)
      end
    end

    it "allows users with explicit ministry permission" do
      church = create(:church)
      membership = create(:church_membership, church:)
      role = create(:role, church:)
      ministry = create(:ministry, church:)
      permission = create(:permission, module_key: "ministries", action_key: "create", name: "Ministerios - Crear/editar")

      create(:membership_role, church_membership: membership, role:)
      create(:role_permission, role:, permission:)

      Current.set(user: membership.user, church:, church_membership: membership) do
        expect(described_class.new(membership.user, ministry).update?).to be(true)
      end
    end
  end

  describe "scope" do
    it "only returns ministries for the current church" do
      church = create(:church)
      visible_ministry = create(:ministry, church:)
      create(:ministry)
      membership = create(:church_membership, :owner, church:)

      Current.set(user: membership.user, church:, church_membership: membership) do
        resolved = described_class::Scope.new(Current.user, Ministry).resolve

        expect(resolved).to contain_exactly(visible_ministry)
      end
    end
  end

  describe "ministry leader implicit scope" do
    let(:church) { create(:church) }
    let(:user) { create(:user) }
    let!(:membership) { create(:church_membership, user:, church:) }
    let(:member) { create(:member, user:, church:) }
    let(:ministry) { create(:ministry, church:) }
    let(:other_ministry) { create(:ministry, church:) }

    it "allows show? when user is leader of that ministry" do
      create(:ministry_membership, member:, ministry:, ministry_role: :leader, status: :active)

      Current.set(user:, church:, church_membership: membership) do
        expect(described_class.new(user, ministry).show?).to be(true)
      end
    end

    it "allows show? when user is co_leader of that ministry" do
      create(:ministry_membership, member:, ministry:, ministry_role: :co_leader, status: :active)

      Current.set(user:, church:, church_membership: membership) do
        expect(described_class.new(user, ministry).show?).to be(true)
      end
    end

    it "denies show? when user is only member (not leader) of the ministry" do
      create(:ministry_membership, member:, ministry:, ministry_role: :member, status: :active)

      Current.set(user:, church:, church_membership: membership) do
        expect(described_class.new(user, ministry).show?).to be(false)
      end
    end

    it "denies show? for a ministry where the user is not a leader" do
      create(:ministry_membership, member:, ministry:, ministry_role: :leader, status: :active)

      Current.set(user:, church:, church_membership: membership) do
        expect(described_class.new(user, other_ministry).show?).to be(false)
      end
    end

    it "allows update? when user is leader of that ministry" do
      create(:ministry_membership, member:, ministry:, ministry_role: :leader, status: :active)

      Current.set(user:, church:, church_membership: membership) do
        expect(described_class.new(user, ministry).update?).to be(true)
      end
    end

    describe "Scope" do
      it "returns only led ministries when user has no church-wide permission" do
        create(:ministry_membership, member:, ministry:, ministry_role: :leader, status: :active)

        Current.set(user:, church:, church_membership: membership) do
          resolved = described_class::Scope.new(user, Ministry).resolve
          expect(resolved).to contain_exactly(ministry)
        end
      end

      it "returns no ministries when user is not a leader anywhere" do
        Current.set(user:, church:, church_membership: membership) do
          resolved = described_class::Scope.new(user, Ministry).resolve
          expect(resolved).to be_empty
        end
      end

      it "returns all church ministries when user has church-wide permission" do
        role = create(:role, church:)
        perm = Permission.find_by(module_key: "ministries", action_key: "read") ||
               create(:permission, module_key: "ministries", action_key: "read", name: "Ministerios - Leer")
        create(:role_permission, role:, permission: perm)
        create(:membership_role, church_membership: membership, role:)

        Current.set(user:, church:, church_membership: membership) do
          resolved = described_class::Scope.new(user, Ministry).resolve
          expect(resolved).to contain_exactly(ministry, other_ministry)
        end
      end
    end
  end
end
