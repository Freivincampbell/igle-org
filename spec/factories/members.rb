FactoryBot.define do
  factory :member do
    church
    sequence(:first_name) { |number| "Miembro #{number}" }
    last_name { "Prueba" }
    second_last_name { "Iglesia" }
    sequence(:email) { |number| "member-#{number}@example.test" }
    phone { "555-0100" }
    birth_date { 30.years.ago.to_date }
    gender { "not_specified" }
    marital_status { "single" }
    children_count { 0 }
    member_status { "active" }
    official_membership_on { Date.current }

    trait :inactive do
      member_status { "inactive" }
    end
  end
end
