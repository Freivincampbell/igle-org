FactoryBot.define do
  factory :church do
    sequence(:name) { |number| "Iglesia #{number}" }
    email { "church@example.test" }
    phone { "555-0100" }
    locale { "es" }
    time_zone { "America/Costa_Rica" }
    status { "active" }

    trait :inactive do
      status { "inactive" }
    end
  end
end
