require "rails_helper"

RSpec.describe Reports::MembersByMinistryReport do
  let(:church) { create(:church) }

  it "lista membresías activas de ministerio scopeadas por iglesia" do
    ministry = create(:ministry, church:, name: "Alabanza")
    member = create(:member, church:, first_name: "Juan")
    create(:ministry_membership, ministry:, member:, ministry_role: :leader, status: :active)

    other_ministry = create(:ministry, name: "Otra")
    other_member = create(:member, church: other_ministry.church)
    create(:ministry_membership, ministry: other_ministry, member: other_member, status: :active)

    rows = described_class.new(church:).rows

    expect(rows.size).to eq(1)
    expect(rows.first[:ministry]).to eq("Alabanza")
    expect(rows.first[:member]).to eq(member.full_name)
    expect(rows.first[:ministry_role]).to eq("Líder")
  end

  it "filtra por ministry_id" do
    a = create(:ministry, church:, name: "A")
    b = create(:ministry, church:, name: "B")
    ma = create(:member, church:)
    mb = create(:member, church:)
    create(:ministry_membership, ministry: a, member: ma, status: :active)
    create(:ministry_membership, ministry: b, member: mb, status: :active)

    rows = described_class.new(church:, filters: { ministry_id: a.id }).rows

    expect(rows.map { |r| r[:ministry] }).to contain_exactly("A")
  end
end
