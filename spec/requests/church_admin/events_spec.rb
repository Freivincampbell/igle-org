require "rails_helper"

RSpec.describe "Church admin events" do
  def event_params(overrides = {})
    {
      title: "Culto especial",
      event_type: "service",
      visibility: "members_only",
      status: "scheduled",
      starts_at: 1.week.from_now.change(hour: 10).iso8601,
      ends_at: 1.week.from_now.change(hour: 12).iso8601,
      location: "Templo",
      recurring: "0",
      recurrence_frequency: "none"
    }.merge(overrides)
  end

  describe "access control" do
    it "requires authentication" do
      church = create(:church)

      get church_admin_events_path(church)

      expect(response).to redirect_to(new_user_session_path)
    end

    it "rejects users without access to the church" do
      church = create(:church)
      sign_in create(:user)

      get church_admin_events_path(church)

      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET new" do
    it "renders the responsible tag search using public_id, not the internal id" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)
      create(:member, church:, first_name: "Ana", last_name: "Lopez", second_last_name: "Diaz")

      sign_in membership.user

      get new_church_admin_event_path(church)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("member-results-responsible")
      expect(response.body).to include(search_church_admin_members_path(church))
    end
  end

  describe "GET index" do
    it "lists events only for the current church" do
      church_a = create(:church)
      church_b = create(:church)
      visible_event = create(:event, church: church_a, title: "Visible")
      hidden_event = create(:event, church: church_b, title: "Oculto")

      membership = create(:church_membership, :owner, church: church_a)
      sign_in membership.user

      get church_admin_events_path(church_a)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(visible_event.title)
      expect(response.body).not_to include(hidden_event.title)
    end
  end

  describe "POST create" do
    it "creates an event for the church" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)

      sign_in membership.user

      expect do
        post church_admin_events_path(church), params: { event: event_params }
      end.to change(Event, :count).by(1)

      event = church.events.last
      expect(event.title).to eq("Culto especial")
      expect(event.created_by).to eq(membership.user)
    end

    it "assigns the responsible member resolved by public_id" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)
      member = create(:member, church:)

      sign_in membership.user

      post church_admin_events_path(church), params: {
        event: event_params(responsible_member_public_id: member.public_id)
      }

      expect(church.events.last.responsible_member).to eq(member)
    end

    it "rejects ministry from another church" do
      church = create(:church)
      foreign_ministry = create(:ministry)
      membership = create(:church_membership, :owner, church:)

      sign_in membership.user

      post church_admin_events_path(church), params: { event: event_params(ministry_id: foreign_ministry.id) }

      expect(response).to have_http_status(:unprocessable_content)
      expect(church.events).to be_empty
    end
  end

  describe "PATCH update" do
    it "updates the responsible member resolved by public_id" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)
      event = create(:event, church:)
      member = create(:member, church:)

      sign_in membership.user

      patch church_admin_event_path(church, event), params: {
        event: event_params(responsible_member_public_id: member.public_id)
      }

      expect(event.reload.responsible_member).to eq(member)
    end
  end

  describe "GET attendance" do
    it "renders attendance checkboxes using public_id, not the internal id" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)
      event = create(:event, church:)
      member = create(:member, church:)

      sign_in membership.user

      get attendance_church_admin_event_path(church, event)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(id="attendance_member_#{member.public_id}"))
      expect(response.body).not_to include(%(id="attendance_member_#{member.id}"))
    end
  end

  describe "PATCH update_attendance" do
    it "records and removes attendance for active members by public_id" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)
      event = create(:event, church:)
      member_a = create(:member, church:)
      member_b = create(:member, church:)

      sign_in membership.user

      patch attendance_church_admin_event_path(church, event), params: {
        attendance: { member_ids: [ member_a.public_id ] }
      }

      expect(event.event_attendances.pluck(:member_id)).to contain_exactly(member_a.id)

      patch attendance_church_admin_event_path(church, event), params: {
        attendance: { member_ids: [ member_b.public_id ] }
      }

      expect(event.reload.event_attendances.pluck(:member_id)).to contain_exactly(member_b.id)
    end
  end

  describe "cancel/reschedule" do
    it "cancels and reschedules an event" do
      church = create(:church)
      membership = create(:church_membership, :owner, church:)
      event = create(:event, church:)

      sign_in membership.user

      patch cancel_church_admin_event_path(church, event)
      expect(event.reload).to be_cancelled

      patch reschedule_church_admin_event_path(church, event)
      expect(event.reload).to be_scheduled
    end
  end

  describe "public id routing" do
    it "does not resolve event database ids" do
      church = create(:church)
      event = create(:event, church:)
      membership = create(:church_membership, :owner, church:)

      sign_in membership.user

      get "/churches/#{church.public_id}/admin/events/#{event.id}"

      expect(response).to have_http_status(:not_found)
    end
  end
end
