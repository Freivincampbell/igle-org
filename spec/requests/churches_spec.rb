require "rails_helper"

RSpec.describe "Churches" do
  describe "GET /churches" do
    it "lists only churches where the user has active membership" do
      visible_church = create(:church, name: "Iglesia Visible")
      hidden_church = create(:church, name: "Iglesia Oculta")
      membership = create(:church_membership, church: visible_church)
      create(:church_membership, :inactive, user: membership.user, church: hidden_church)

      sign_in membership.user
      get churches_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Iglesia Visible")
      expect(response.body).not_to include("Iglesia Oculta")
    end
  end

  describe "GET /churches/:public_id" do
    it "shows a church using public_id instead of database id" do
      church = create(:church)
      membership = create(:church_membership, church:)

      sign_in membership.user
      get church_path(church)

      expect(response).to have_http_status(:ok)
      expect(request.path).to eq("/churches/#{church.public_id}")
      expect(request.path).not_to eq("/churches/#{church.id}")
      expect(response.body).to include(church.name)
    end

    it "does not resolve numeric database ids" do
      church = create(:church)
      membership = create(:church_membership, church:)

      sign_in membership.user
      get "/churches/#{church.id}"

      expect(response).to have_http_status(:not_found)
    end

    it "prevents users from viewing another church" do
      church = create(:church)
      other_membership = create(:church_membership)

      sign_in other_membership.user
      get church_path(church)

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq(I18n.t("authorization.not_authorized"))
    end
  end
end
