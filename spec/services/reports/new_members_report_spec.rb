require "rails_helper"

RSpec.describe Reports::NewMembersReport do
  let(:church) { create(:church) }

  it "filtra por mes de membresía (YYYY-MM)" do
    in_month = create(:member, church:, official_membership_on: Date.new(2026, 3, 10), first_name: "Marzo")
    out_month = create(:member, church:, official_membership_on: Date.new(2026, 4, 10), first_name: "Abril")

    rows = described_class.new(church:, filters: { month: "2026-03" }).rows
    names = rows.map { |r| r[:full_name] }

    expect(names).to include(in_month.full_name)
    expect(names).not_to include(out_month.full_name)
  end

  it "aísla por iglesia" do
    create(:member, official_membership_on: Date.new(2026, 3, 10), first_name: "Otra")
    rows = described_class.new(church:, filters: { month: "2026-03" }).rows
    expect(rows).to be_empty
  end
end
