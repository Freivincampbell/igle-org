FactoryBot.define do
  factory :user do
    sequence(:email) { |number| "user-#{number}@example.test" }
    first_name { "Test" }
    last_name { "User" }
    password { Devise.friendly_token.first(24) }
    password_confirmation { password }
    platform_role { "user" }
    status { "active" }

    trait :super_admin do
      platform_role { "super_admin" }
    end

    trait :inactive do
      status { "inactive" }
    end
  end
end
