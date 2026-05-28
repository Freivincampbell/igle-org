require "rails_helper"

RSpec.describe "Church admin ministries" do
  def ministry_params(overrides = {})
    {
      name: "Alabanza",
      description: "Equipo de adoracion",
      status: "active"
    }.merge(overrides)
  end

  describe "access control" do
    it "requires authentication" do
      church = create(:church)

      get church_admin_ministries_path(church)

      expect(response).to redirect_to(new_user_session_path)
    end

    it "requires access to the church" do
      church = create(:church)
      sign_in create(:user)

      get church_admin_ministries_path(church)

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq(I18n.t("authorization.not_authorized"))
    end
  end

  describe "GET /churches/:church_public_id/admin/ministries" do
    it "lists ministries for the current church only" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)
      visible_ministry = create(:ministry, church:, name: "Visible")
      hidden_ministry = create(:ministry, name: "Oculto")

      sign_in membership.user

      get church_admin_ministries_path(church)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(visible_ministry.name)
      expect(response.body).not_to include(hidden_ministry.name)
    end
  end

  describe "POST /churches/:church_public_id/admin/ministries" do
    it "creates a ministry" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)

      sign_in membership.user

      expect do
        post church_admin_ministries_path(church), params: { ministry: ministry_params }
      end.to change(Ministry, :count).by(1)

      ministry = church.ministries.find_by!(name: "Alabanza")

      expect(response).to redirect_to(church_admin_ministry_path(church, ministry))
      expect(ministry.description).to eq("Equipo de adoracion")
    end
  end

  describe "PATCH /churches/:church_public_id/admin/ministries/:public_id" do
    it "updates ministry details" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)
      ministry = create(:ministry, church:, name: "Viejo")

      sign_in membership.user

      patch church_admin_ministry_path(church, ministry), params: {
        ministry: ministry_params(name: "Nuevo")
      }

      expect(response).to redirect_to(church_admin_ministry_path(church, ministry))
      expect(ministry.reload.name).to eq("Nuevo")
    end
  end

  describe "PATCH /churches/:church_public_id/admin/ministries/:public_id/members" do
    it "assigns active church members to a ministry" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)
      ministry = create(:ministry, church:)
      member = create(:member, church:)

      sign_in membership.user

      patch members_church_admin_ministry_path(church, ministry), params: {
        ministry: {
          member_public_ids: [ member.public_id ],
          member_roles: { member.public_id => "leader" }
        }
      }

      ministry_membership = ministry.ministry_memberships.find_by!(member:)

      expect(response).to redirect_to(church_admin_ministry_path(church, ministry))
      expect(ministry_membership).to be_active
      expect(ministry_membership).to be_leader
    end

    it "rejects members from another church" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)
      ministry = create(:ministry, church:)
      other_member = create(:member)

      sign_in membership.user

      patch members_church_admin_ministry_path(church, ministry), params: {
        ministry: {
          member_public_ids: [ other_member.public_id ],
          member_roles: { other_member.public_id => "member" }
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(ministry.ministry_memberships).to be_empty
    end
  end

  describe "activation" do
    it "deactivates and activates a ministry" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)
      ministry = create(:ministry, church:)

      sign_in membership.user

      patch deactivate_church_admin_ministry_path(church, ministry)
      expect(response).to redirect_to(church_admin_ministry_path(church, ministry))
      expect(ministry.reload).to be_inactive

      patch activate_church_admin_ministry_path(church, ministry)
      expect(response).to redirect_to(church_admin_ministry_path(church, ministry))
      expect(ministry.reload).to be_active
    end
  end

  describe "public id routing" do
    it "does not resolve ministry database ids" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)
      ministry = create(:ministry, church:)

      sign_in membership.user

      get "/churches/#{church.public_id}/admin/ministries/#{ministry.id}"

      expect(response).to have_http_status(:not_found)
    end
  end
end
