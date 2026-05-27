FactoryBot.define do
  factory :church_membership do
    church
    user
    owner { false }
    status { "active" }

    trait :owner do
      owner { true }
    end

    trait :inactive do
      status { "inactive" }
    end
  end
end
