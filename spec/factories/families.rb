FactoryBot.define do
  factory :family do
    association :church
    sequence(:name) { |n| "Familia #{n}" }
    status { "active" }
  end

  factory :family_member do
    association :church
    association :family
    association :member
    relationship { "other" }

    after(:build) do |fm|
      fm.church ||= fm.family&.church
      fm.member&.update_columns(church_id: fm.church_id) if fm.member && fm.member.church_id != fm.church_id
      fm.family&.update_columns(church_id: fm.church_id) if fm.family && fm.family.church_id != fm.church_id
    end
  end
end
