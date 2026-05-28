require "rails_helper"

RSpec.describe "Church admin service times" do
  describe "access control" do
    it "requires authentication" do
      church = create(:church)

      get church_admin_service_times_path(church)

      expect(response).to redirect_to(new_user_session_path)
    end

    it "rejects users without access to the church" do
      church = create(:church)
      sign_in create(:user)

      get church_admin_service_times_path(church)

      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET index" do
    it "lists service times for the current church only" do
      church_a = create(:church)
      church_b = create(:church)
      visible = create(:church_service_time, church: church_a, name: "Visible")
      hidden = create(:church_service_time, church: church_b, name: "Oculto")

      membership = create(:church_membership, :owner, church: church_a)
      sign_in membership.user

      get church_admin_service_times_path(church_a)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(visible.name)
      expect(response.body).not_to include(hidden.name)
    end
  end

  describe "POST create" do
    it "creates a service time for the church" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)

      sign_in membership.user

      expect do
        post church_admin_service_times_path(church), params: {
          church_service_time: {
            name: "Culto domingo",
            day_of_week: 0,
            starts_at: "10:00",
            ends_at: "12:00",
            location: "Templo",
            status: "active"
          }
        }
      end.to change(ChurchServiceTime, :count).by(1)

      expect(response).to redirect_to(church_admin_service_times_path(church))
      expect(church.church_service_times.last.name).to eq("Culto domingo")
    end

    it "rejects when ends_at is before starts_at" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)

      sign_in membership.user

      post church_admin_service_times_path(church), params: {
        church_service_time: {
          name: "Invalido",
          day_of_week: 0,
          starts_at: "12:00",
          ends_at: "10:00",
          status: "active"
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(ChurchServiceTime).not_to exist(name: "Invalido")
    end
  end

  describe "activation" do
    it "deactivates and activates a service time" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)
      service_time = create(:church_service_time, church:)

      sign_in membership.user

      patch deactivate_church_admin_service_time_path(church, service_time)
      expect(service_time.reload).to be_inactive

      patch activate_church_admin_service_time_path(church, service_time)
      expect(service_time.reload).to be_active
    end
  end

  describe "public id routing" do
    it "does not resolve service time database ids" do
      church = create(:church)
      service_time = create(:church_service_time, church:)
      membership = create(:church_membership, :owner, church:)

      sign_in membership.user

      get "/churches/#{church.public_id}/admin/service_times/#{service_time.id}/edit"

      expect(response).to have_http_status(:not_found)
    end
  end
end
