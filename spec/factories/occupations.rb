FactoryBot.define do
  factory :occupation do
    association :church
    sequence(:name) { |n| "Ocupacion #{n}" }
    status { "active" }
  end

  factory :skill do
    association :church
    sequence(:name) { |n| "Habilidad #{n}" }
    status { "active" }
  end

  factory :member_occupation do
    association :church
    association :member
    association :occupation
    employment_status { "employed" }
    current { true }

    after(:build) do |mo|
      mo.church ||= mo.member&.church
      mo.member&.update_columns(church_id: mo.church_id) if mo.member && mo.member.church_id != mo.church_id
      mo.occupation&.update_columns(church_id: mo.church_id) if mo.occupation && mo.occupation.church_id != mo.church_id
    end
  end

  factory :member_skill do
    association :church
    association :member
    association :skill
    level { "basic" }

    after(:build) do |ms|
      ms.church ||= ms.member&.church
      ms.member&.update_columns(church_id: ms.church_id) if ms.member && ms.member.church_id != ms.church_id
      ms.skill&.update_columns(church_id: ms.church_id) if ms.skill && ms.skill.church_id != ms.church_id
    end
  end
end
