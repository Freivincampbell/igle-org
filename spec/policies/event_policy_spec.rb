require "rails_helper"

RSpec.describe EventPolicy do
  let(:church) { create(:church) }
  let(:user) { create(:user) }
  let(:membership) { create(:church_membership, user:, church:) }
  let(:member) { membership && create(:member, user:, church:) }
  let(:ministry) { create(:ministry, church:) }
  let(:other_ministry) { create(:ministry, church:) }
  let(:event_in_ministry) { create(:event, church:, ministry:) }
  let(:event_in_other_ministry) { create(:event, church:, ministry: other_ministry) }
  let(:event_no_ministry) { create(:event, church:, ministry: nil) }

  describe "show? for ministry leader" do
    it "allows show? when user is leader of the event's ministry" do
      create(:ministry_membership, member:, ministry:, ministry_role: :leader, status: :active)

      Current.set(user:, church:, church_membership: membership) do
        expect(described_class.new(user, event_in_ministry).show?).to be(true)
      end
    end

    it "denies show? for event in a ministry where user is not leader" do
      create(:ministry_membership, member:, ministry:, ministry_role: :leader, status: :active)

      Current.set(user:, church:, church_membership: membership) do
        expect(described_class.new(user, event_in_other_ministry).show?).to be(false)
      end
    end

    it "denies show? for event with no ministry when user is only a leader" do
      create(:ministry_membership, member:, ministry:, ministry_role: :leader, status: :active)

      Current.set(user:, church:, church_membership: membership) do
        expect(described_class.new(user, event_no_ministry).show?).to be(false)
      end
    end
  end

  describe "Scope" do
    it "returns only events of led ministries when user has no church-wide permission" do
      create(:ministry_membership, member:, ministry:, ministry_role: :leader, status: :active)
      event_in_ministry
      event_in_other_ministry
      event_no_ministry

      Current.set(user:, church:, church_membership: membership) do
        resolved = described_class::Scope.new(user, Event).resolve
        expect(resolved).to contain_exactly(event_in_ministry)
      end
    end

    it "returns no events when user is not a leader anywhere and has no permission" do
      event_in_ministry
      event_no_ministry

      Current.set(user:, church:, church_membership: membership) do
        resolved = described_class::Scope.new(user, Event).resolve
        expect(resolved).to be_empty
      end
    end

    it "returns all church events when user has church-wide events permission" do
      role = create(:role, church:)
      perm = Permission.find_by(module_key: "events", action_key: "read") ||
             create(:permission, module_key: "events", action_key: "read", name: "Eventos - Leer")
      create(:role_permission, role:, permission: perm)
      create(:membership_role, church_membership: membership, role:)
      event_in_ministry
      event_in_other_ministry
      event_no_ministry

      Current.set(user:, church:, church_membership: membership) do
        resolved = described_class::Scope.new(user, Event).resolve
        expect(resolved).to contain_exactly(event_in_ministry, event_in_other_ministry, event_no_ministry)
      end
    end

    it "does not return events from another church" do
      other_church = create(:church)
      other_event = create(:event, church: other_church)
      create(:ministry_membership, member:, ministry:, ministry_role: :leader, status: :active)

      Current.set(user:, church:, church_membership: membership) do
        resolved = described_class::Scope.new(user, Event).resolve
        expect(resolved).not_to include(other_event)
      end
    end

    it "returns all events for owner" do
      owner_membership = create(:church_membership, :owner, church:)
      event_in_ministry
      event_no_ministry

      Current.set(user: owner_membership.user, church:, church_membership: owner_membership) do
        resolved = described_class::Scope.new(owner_membership.user, Event).resolve
        expect(resolved).to contain_exactly(event_in_ministry, event_no_ministry)
      end
    end
  end
end
