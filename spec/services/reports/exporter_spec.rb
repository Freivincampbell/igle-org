require "rails_helper"

RSpec.describe Reports::Exporter do
  let(:report) do
    instance_double(
      Reports::BaseReport,
      title: "Reporte demo",
      filename: "demo",
      columns: [ { key: :name, label: "Nombre" }, { key: :age, label: "Edad" } ],
      rows: [ { name: "Ana", age: 30 }, { name: "Luis", age: 25 } ]
    )
  end

  describe "#to_csv" do
    it "genera encabezados y filas" do
      csv = described_class.new(report).to_csv

      expect(csv).to include("Nombre,Edad")
      expect(csv).to include("Ana,30")
      expect(csv).to include("Luis,25")
    end
  end

  describe "#to_xlsx" do
    it "genera un binario xlsx no vacío" do
      data = described_class.new(report).to_xlsx

      expect(data).to be_a(String)
      expect(data.bytesize).to be > 0
      expect(data[0, 2]).to eq("PK")
    end
  end
end
