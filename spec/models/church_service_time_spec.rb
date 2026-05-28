require "rails_helper"

RSpec.describe ChurchServiceTime do
  describe "validations" do
    it "requires name, day_of_week and starts_at" do
      service_time = ChurchServiceTime.new

      service_time.valid?

      expect(service_time.errors).to include(:church, :name, :day_of_week, :starts_at)
    end

    it "rejects an end time before or equal to start time" do
      service_time = build(:church_service_time, starts_at: "10:00", ends_at: "10:00")

      expect(service_time).not_to be_valid
      expect(service_time.errors[:ends_at]).to be_present
    end

    it "allows blank ends_at" do
      service_time = build(:church_service_time, ends_at: nil)

      expect(service_time).to be_valid
    end

    it "rejects day_of_week outside 0..6" do
      service_time = build(:church_service_time, day_of_week: 7)

      expect(service_time).not_to be_valid
      expect(service_time.errors[:day_of_week]).to be_present
    end
  end

  describe ".ordered" do
    it "orders by day_of_week first" do
      church = create(:church)
      wednesday = create(:church_service_time, church:, name: "Servicio", day_of_week: 3)
      sunday = create(:church_service_time, church:, name: "Culto", day_of_week: 0)

      ordered = church.church_service_times.ordered.to_a

      expect(ordered.first).to eq(sunday)
      expect(ordered.last).to eq(wednesday)
    end
  end

  describe "multi-tenant isolation" do
    it "only returns service times of the given church" do
      church_a = create(:church)
      church_b = create(:church)
      service_a = create(:church_service_time, church: church_a, name: "Culto A")
      service_b = create(:church_service_time, church: church_b, name: "Culto B")

      expect(church_a.church_service_times).to include(service_a)
      expect(church_a.church_service_times).not_to include(service_b)
    end
  end
end
