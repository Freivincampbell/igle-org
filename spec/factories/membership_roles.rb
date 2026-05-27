FactoryBot.define do
  factory :membership_role do
    church_membership
    role { association(:role, church: church_membership.church) }
  end
end
