require "rails_helper"

RSpec.describe "Member portal profile change requests" do
  it "creates a pending request only for fields that changed" do
    church = create(:church)
    user = create(:user)
    create(:church_membership, church:, user:)
    member = create(:member, church:, user:, phone: "111", first_name: "Igor")

    sign_in user

    expect do
      post church_member_portal_profile_change_requests_path(church), params: {
        profile_change_request: {
          first_name: "Igor",
          phone: "222",
          email: "new@example.test"
        }
      }
    end.to change(ProfileChangeRequest, :count).by(1)

    req = ProfileChangeRequest.last
    expect(req.changes_payload).to include("phone" => "222", "email" => "new@example.test")
    expect(req.changes_payload).not_to include("first_name")
    expect(req).to be_pending
  end

  it "rejects when no changes were proposed" do
    church = create(:church)
    user = create(:user)
    create(:church_membership, church:, user:)
    member = create(:member, church:, user:, phone: "111")

    sign_in user

    post church_member_portal_profile_change_requests_path(church), params: {
      profile_change_request: { phone: "111" }
    }

    expect(response).to have_http_status(:unprocessable_content)
    expect(ProfileChangeRequest.count).to eq(0)
  end
end
