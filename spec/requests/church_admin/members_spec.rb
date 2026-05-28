require "rails_helper"

RSpec.describe "Church admin members" do
  def member_params(overrides = {})
    {
      first_name: "Ana",
      middle_name: "Maria",
      last_name: "Rojas",
      second_last_name: "Solis",
      email: "ana@example.test",
      phone: "555-0199",
      secondary_phone: "555-0101",
      birth_date: "1990-01-15",
      gender: "female",
      marital_status: "married",
      children_count: 2,
      baptized_on: "2010-06-01",
      official_membership_on: "2020-01-01",
      member_status: "active",
      address_line_1: "Calle 1",
      city: "San Jose",
      country: "Costa Rica",
      emergency_contact_name: "Carlos Rojas",
      emergency_contact_phone: "555-0111"
    }.merge(overrides)
  end

  describe "access control" do
    it "requires authentication" do
      church = create(:church)

      get church_admin_members_path(church)

      expect(response).to redirect_to(new_user_session_path)
    end

    it "requires access to the church" do
      church = create(:church)
      sign_in create(:user)

      get church_admin_members_path(church)

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq(I18n.t("authorization.not_authorized"))
    end
  end

  describe "GET /churches/:church_public_id/admin/members" do
    it "lists members for the current church only" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)
      visible_member = create(:member, church:, first_name: "Visible")
      hidden_member = create(:member, first_name: "Oculto")

      sign_in membership.user

      get church_admin_members_path(church)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(visible_member.first_name)
      expect(response.body).not_to include(hidden_member.first_name)
    end
  end

  describe "POST /churches/:church_public_id/admin/members" do
    it "creates a member" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)

      sign_in membership.user

      expect do
        post church_admin_members_path(church), params: { member: member_params }
      end.to change(Member, :count).by(1)

      member = church.members.find_by!(email: "ana@example.test")

      expect(response).to redirect_to(church_admin_member_path(church, member))
      expect(member.full_name).to eq("Ana Maria Rojas Solis")
      expect(member.address_line_1).to eq("Calle 1")
    end

    it "can link a member to an existing user from the same church" do
      church = create(:church)
      owner_membership = create(:church_membership, :owner, church:)
      user_membership = create(:church_membership, church:)

      sign_in owner_membership.user

      post church_admin_members_path(church), params: {
        member: member_params(email: "linked@example.test", user_id: user_membership.user_id)
      }

      expect(response).to redirect_to(church_admin_member_path(church, Member.last))
      expect(Member.last.user).to eq(user_membership.user)
    end

    it "rejects users from another church" do
      church = create(:church)
      owner_membership = create(:church_membership, :owner, church:)
      other_user = create(:user)

      sign_in owner_membership.user

      post church_admin_members_path(church), params: {
        member: member_params(user_id: other_user.id)
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(Member).not_to exist(email: "ana@example.test")
    end
  end

  describe "PATCH /churches/:church_public_id/admin/members/:public_id" do
    it "updates member profile details" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)
      member = create(:member, church:, first_name: "Viejo")

      sign_in membership.user

      patch church_admin_member_path(church, member), params: {
        member: member_params(first_name: "Nuevo", email: "nuevo@example.test")
      }

      expect(response).to redirect_to(church_admin_member_path(church, member))
      expect(member.reload.first_name).to eq("Nuevo")
      expect(member.email).to eq("nuevo@example.test")
    end
  end

  describe "activation" do
    it "deactivates and activates a member" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)
      member = create(:member, church:)

      sign_in membership.user

      patch deactivate_church_admin_member_path(church, member)
      expect(response).to redirect_to(church_admin_member_path(church, member))
      expect(member.reload).to be_inactive

      patch activate_church_admin_member_path(church, member)
      expect(response).to redirect_to(church_admin_member_path(church, member))
      expect(member.reload).to be_active
    end
  end

  describe "public id routing" do
    it "does not resolve member database ids" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)
      member = create(:member, church:)

      sign_in membership.user

      get "/churches/#{church.public_id}/admin/members/#{member.id}"

      expect(response).to have_http_status(:not_found)
    end
  end
end
