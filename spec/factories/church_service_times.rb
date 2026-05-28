FactoryBot.define do
  factory :church_service_time do
    association :church
    sequence(:name) { |n| "Culto #{n}" }
    day_of_week { 0 }
    starts_at { "10:00" }
    ends_at { "12:00" }
    location { "Templo principal" }
    status { "active" }
    position { 0 }

    trait :inactive do
      status { "inactive" }
    end
  end
end
