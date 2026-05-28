FactoryBot.define do
  factory :ministry do
    church
    sequence(:name) { |number| "Ministerio #{number}" }
    description { "Ministerio de prueba" }
    status { "active" }

    trait :inactive do
      status { "inactive" }
    end
  end
end
