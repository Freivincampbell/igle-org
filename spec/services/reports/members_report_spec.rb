require "rails_helper"

RSpec.describe Reports::MembersReport do
  let(:church) { create(:church) }

  it "expone columnas con encabezados en español" do
    report = described_class.new(church:)
    labels = report.columns.map { |c| c[:label] }
    expect(labels).to include("Nombre completo", "Teléfono", "Estado")
  end

  it "incluye solo miembros de la iglesia actual (aislamiento)" do
    mine = create(:member, church:, first_name: "Ana")
    other = create(:member, first_name: "Otra")

    names = described_class.new(church:).rows.map { |r| r[:full_name] }

    expect(names).to include(mine.full_name)
    expect(names).not_to include(other.full_name)
  end

  it "filtra por estado activo" do
    active = create(:member, church:, member_status: "active", first_name: "Activo")
    inactive = create(:member, church:, member_status: "inactive", first_name: "Inactivo")

    rows = described_class.new(church:, filters: { status: "active" }).rows
    names = rows.map { |r| r[:full_name] }

    expect(names).to include(active.full_name)
    expect(names).not_to include(inactive.full_name)
  end

  it "filtra por estado inactivo" do
    create(:member, church:, member_status: "active", first_name: "Activo")
    inactive = create(:member, church:, member_status: "inactive", first_name: "Inactivo")

    rows = described_class.new(church:, filters: { status: "inactive" }).rows

    expect(rows.map { |r| r[:full_name] }).to contain_exactly(inactive.full_name)
  end
end
