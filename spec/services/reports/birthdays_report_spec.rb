require "rails_helper"

RSpec.describe Reports::BirthdaysReport do
  let(:church) { create(:church) }

  it "filtra por mes de nacimiento y ordena por día" do
    early = create(:member, church:, birth_date: Date.new(1990, 5, 3), first_name: "Tres")
    late = create(:member, church:, birth_date: Date.new(1985, 5, 20), first_name: "Veinte")
    create(:member, church:, birth_date: Date.new(1990, 6, 1), first_name: "Junio")

    rows = described_class.new(church:, filters: { month: "5" }).rows

    expect(rows.map { |r| r[:full_name] }).to eq([ early.full_name, late.full_name ])
    expect(rows.first[:day]).to eq(3)
  end

  it "aísla por iglesia" do
    create(:member, birth_date: Date.new(1990, 5, 3), first_name: "Otra")
    rows = described_class.new(church:, filters: { month: "5" }).rows
    expect(rows).to be_empty
  end
end
