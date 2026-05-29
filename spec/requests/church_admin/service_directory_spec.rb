require "rails_helper"

RSpec.describe "Church admin service directory" do
  it "requires authentication" do
    church = create(:church)
    get church_admin_service_directory_path(church)
    expect(response).to redirect_to(new_user_session_path)
  end

  it "shows only members of the current church offering services" do
    church_a = create(:church)
    church_b = create(:church)
    membership = create(:church_membership, :owner, church: church_a)

    member_offers = create(:member, church: church_a, first_name: "Ofreciendo")
    member_looking = create(:member, church: church_a, first_name: "Cesar")
    foreign_member = create(:member, church: church_b, first_name: "Externita")

    create(:member_occupation, church: church_a, member: member_offers, offers_services: true)
    create(:member_occupation, church: church_a, member: member_looking, looking_for_work: true)
    create(:member_occupation, church: church_b, member: foreign_member, offers_services: true)

    sign_in membership.user

    get church_admin_service_directory_path(church_a), params: { filter: "offers" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(member_offers.first_name)
    expect(response.body).not_to include(member_looking.first_name)
    expect(response.body).not_to include(foreign_member.first_name)
  end

  it "filters by looking_for_work" do
    church = create(:church)
    membership = create(:church_membership, :owner, church:)
    member = create(:member, church:, first_name: "Soledad")
    create(:member_occupation, church:, member:, looking_for_work: true)

    sign_in membership.user

    get church_admin_service_directory_path(church), params: { filter: "looking_for_work" }

    expect(response.body).to include(member.first_name)
  end
end
