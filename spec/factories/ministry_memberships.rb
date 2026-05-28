FactoryBot.define do
  factory :ministry_membership do
    ministry
    member { association(:member, church: ministry.church) }
    ministry_role { "member" }
    status { "active" }

    trait :leader do
      ministry_role { "leader" }
    end

    trait :co_leader do
      ministry_role { "co_leader" }
    end

    trait :inactive do
      status { "inactive" }
    end
  end
end
