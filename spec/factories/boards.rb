FactoryBot.define do
  factory :board do
    association :church
    sequence(:name) { |n| "Junta #{n}" }
    starts_on { Date.current.beginning_of_year }
    ends_on { Date.current.beginning_of_year + 2.years }
    status { "active" }
  end

  factory :board_member do
    association :church
    association :board
    association :member
    position { "president" }
    status { "active" }

    after(:build) do |bm|
      bm.church ||= bm.board&.church
      bm.member&.update_columns(church_id: bm.church_id) if bm.member && bm.member.church_id != bm.church_id
      bm.board&.update_columns(church_id: bm.church_id) if bm.board && bm.board.church_id != bm.church_id
    end
  end
end
