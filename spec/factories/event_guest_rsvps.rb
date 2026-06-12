FactoryBot.define do
  factory :event_guest_rsvp do
    association :church
    event { association(:event, church:, visibility: "public") }
    sequence(:name) { |n| "Invitado #{n}" }
    sequence(:email) { |n| "invitado#{n}@example.com" }
    guests_count { 0 }
    status { "attending" }

    trait :cancelled do
      status { "cancelled" }
    end
  end
end
