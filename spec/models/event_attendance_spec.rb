require "rails_helper"

RSpec.describe EventAttendance do
  it "es válida con miembro" do
    expect(build(:event_attendance)).to be_valid
  end

  it "es válida como walk-in (sin miembro, con guest_name)" do
    attendance = build(:event_attendance, :walk_in)

    expect(attendance.member).to be_nil
    expect(attendance).to be_valid
  end

  it "requiere miembro o guest_name" do
    expect(build(:event_attendance, member: nil, guest_name: nil)).not_to be_valid
  end

  it "asigna occurrence_date al guardar si viene en blanco (fecha del evento)" do
    starts_at = Time.zone.parse("2026-07-05 10:00")
    event = create(:event, starts_at:, ends_at: starts_at + 2.hours)
    attendance = create(:event_attendance, event:, church: event.church, occurrence_date: nil)

    expect(attendance.occurrence_date).to eq(Date.new(2026, 7, 5))
  end

  it "permite asistencia del mismo miembro en dos fechas de ocurrencia distintas" do
    event = create(:event, recurring: true, recurrence_frequency: "weekly")
    member = create(:member, church: event.church)
    create(:event_attendance, event:, church: event.church, member:, occurrence_date: Date.new(2026, 7, 5))

    second = build(:event_attendance, event:, church: event.church, member:, occurrence_date: Date.new(2026, 7, 12))

    expect(second).to be_valid
  end

  it "rechaza duplicado del mismo miembro en la misma fecha de ocurrencia" do
    event = create(:event)
    member = create(:member, church: event.church)
    create(:event_attendance, event:, church: event.church, member:, occurrence_date: Date.new(2026, 7, 5))

    dup = build(:event_attendance, event:, church: event.church, member:, occurrence_date: Date.new(2026, 7, 5))

    expect { dup.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "registra versiones con paper_trail" do
    attendance = create(:event_attendance)

    expect(attendance.versions.count).to eq(1)
  end
end
