FactoryBot.define do
  factory :event do
    association :church
    sequence(:title) { |n| "Evento #{n}" }
    event_type { "service" }
    visibility { "members_only" }
    status { "scheduled" }
    starts_at { 1.day.from_now }
    ends_at { 1.day.from_now + 2.hours }
    recurrence_frequency { "none" }
    recurring { false }
  end

  factory :event_rsvp do
    association :church
    association :event
    association :member
    status { "attending" }
    guests_count { 0 }

    after(:build) do |rsvp|
      rsvp.church ||= rsvp.event&.church
      rsvp.event&.update_columns(church_id: rsvp.church_id) if rsvp.event && rsvp.event.church_id != rsvp.church_id
      rsvp.member&.update_columns(church_id: rsvp.church_id) if rsvp.member && rsvp.member.church_id != rsvp.church_id
    end
  end

  factory :event_attendance do
    association :church
    association :event
    association :member
    attended { true }
    checked_in_at { Time.current }

    after(:build) do |att|
      att.church ||= att.event&.church
      att.event&.update_columns(church_id: att.church_id) if att.event && att.event.church_id != att.church_id
      att.member&.update_columns(church_id: att.church_id) if att.member && att.member.church_id != att.church_id
    end
  end
end
