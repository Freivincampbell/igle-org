require "rails_helper"

RSpec.describe "Church admin profile change requests" do
  it "lists pending requests for the current church only" do
    church_a = create(:church)
    church_b = create(:church)
    owner = create(:church_membership, :owner, church: church_a)
    mem_a = create(:member, church: church_a, first_name: "Visible")
    mem_b = create(:member, church: church_b, first_name: "Oculta")
    create(:profile_change_request, church: church_a, member: mem_a)
    create(:profile_change_request, church: church_b, member: mem_b)

    sign_in owner.user

    get church_admin_profile_change_requests_path(church_a)

    expect(response.body).to include(mem_a.full_name)
    expect(response.body).not_to include(mem_b.full_name)
  end

  it "approves a request and applies the changes" do
    church = create(:church)
    owner = create(:church_membership, :owner, church:)
    member = create(:member, church:, phone: "111")
    req = create(:profile_change_request, church:, member:, changes_payload: { "phone" => "999" })

    sign_in owner.user

    patch approve_church_admin_profile_change_request_path(church, req)

    expect(member.reload.phone).to eq("999")
    expect(req.reload).to be_approved
  end

  it "rejects a request" do
    church = create(:church)
    owner = create(:church_membership, :owner, church:)
    member = create(:member, church:)
    req = create(:profile_change_request, church:, member:)

    sign_in owner.user

    patch reject_church_admin_profile_change_request_path(church, req), params: { review_notes: "Faltan datos" }

    expect(req.reload).to be_rejected
    expect(req.review_notes).to eq("Faltan datos")
  end
end
