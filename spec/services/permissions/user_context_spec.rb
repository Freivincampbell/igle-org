require "rails_helper"

RSpec.describe Permissions::UserContext do
  it "expone los ids de ministerios liderados en la iglesia actual" do
    church = create(:church)
    membership = create(:church_membership, church:)
    member = create(:member, church:, user: membership.user)
    led = create(:ministry, church:)
    other = create(:ministry, church:)
    create(:ministry_membership, ministry: led, member:, ministry_role: "leader", status: "active")
    create(:ministry_membership, ministry: other, member:, ministry_role: "member", status: "active")

    context = described_class.new(user: membership.user, current_church: church, church_membership: membership)

    expect(context.assigned_ministry_ids).to contain_exactly(led.id)
  end

  it "devuelve vacío si el usuario no tiene member en la iglesia" do
    church = create(:church)
    membership = create(:church_membership, church:)

    context = described_class.new(user: membership.user, current_church: church, church_membership: membership)

    expect(context.assigned_ministry_ids).to eq([])
  end
end
