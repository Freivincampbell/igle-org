FactoryBot.define do
  factory :role do
    church
    sequence(:name) { |number| "Role #{number}" }
    status { "active" }
    pastoral { false }

    trait :inactive do
      status { "inactive" }
    end

    trait :pastoral do
      pastoral { true }
    end
  end
end
