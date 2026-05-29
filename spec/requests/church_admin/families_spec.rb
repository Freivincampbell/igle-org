require "rails_helper"

RSpec.describe "Church admin families" do
  describe "access control" do
    it "requires authentication" do
      church = create(:church)

      get church_admin_families_path(church)

      expect(response).to redirect_to(new_user_session_path)
    end

    it "rejects users without access to the church" do
      church = create(:church)
      sign_in create(:user)

      get church_admin_families_path(church)

      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET index" do
    it "lists families for the current church only" do
      church_a = create(:church)
      church_b = create(:church)
      visible = create(:family, church: church_a, name: "Visible")
      hidden = create(:family, church: church_b, name: "Oculta")

      membership = create(:church_membership, :owner, church: church_a)
      sign_in membership.user

      get church_admin_families_path(church_a)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(visible.name)
      expect(response.body).not_to include(hidden.name)
    end
  end

  describe "POST create" do
    it "creates a family" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)

      sign_in membership.user

      expect do
        post church_admin_families_path(church), params: { family: { name: "Mendez", status: "active" } }
      end.to change(Family, :count).by(1)

      expect(response).to redirect_to(church_admin_family_path(church, Family.last))
    end
  end

  describe "PATCH update_members" do
    it "assigns members of the current church only" do
      church = create(:church)
      foreign_church = create(:church)
      membership = create(:church_membership, :owner, church:)
      family = create(:family, church:)
      member_in_church = create(:member, church:)
      member_other_church = create(:member, church: foreign_church)

      sign_in membership.user

      patch members_church_admin_family_path(church, family), params: {
        family: {
          member_public_ids: [ member_in_church.public_id, member_other_church.public_id ],
          member_relationships: { member_in_church.public_id => "spouse" },
          primary_contact_public_id: member_in_church.public_id
        }
      }

      assignment = family.family_members
      expect(assignment.size).to eq(1)
      expect(assignment.first.member).to eq(member_in_church)
      expect(assignment.first.relationship).to eq("spouse")
      expect(assignment.first.primary_contact).to be(true)
    end
  end

  describe "activation" do
    it "deactivates and activates a family" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)
      family = create(:family, church:)

      sign_in membership.user

      patch deactivate_church_admin_family_path(church, family)
      expect(family.reload).to be_inactive

      patch activate_church_admin_family_path(church, family)
      expect(family.reload).to be_active
    end
  end

  describe "public id routing" do
    it "does not resolve family database ids" do
      church = create(:church)
      family = create(:family, church:)
      membership = create(:church_membership, :owner, church:)

      sign_in membership.user

      get "/churches/#{church.public_id}/admin/families/#{family.id}"

      expect(response).to have_http_status(:not_found)
    end
  end
end
