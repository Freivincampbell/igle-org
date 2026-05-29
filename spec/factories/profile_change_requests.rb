FactoryBot.define do
  factory :profile_change_request do
    association :church
    association :member
    status { "pending" }
    changes_payload { { "phone" => "555-1111" } }

    after(:build) do |req|
      req.church ||= req.member&.church
      req.member&.update_columns(church_id: req.church_id) if req.member && req.member.church_id != req.church_id
    end
  end
end
