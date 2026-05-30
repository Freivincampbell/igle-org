require "rails_helper"

RSpec.describe "ChurchAdmin::Members catalog assignment", type: :request do
  let(:church)     { create(:church) }
  let(:membership) { create(:church_membership, :owner, church:) }
  let(:ministry1)  { create(:ministry, church:, status: "active") }
  let(:ministry2)  { create(:ministry, church:, status: "active") }

  before { sign_in membership.user }

  def base_member_params
    {
      first_name: "Ana",
      last_name: "López",
      second_last_name: "Pérez",
      phone: "88887777",
      birth_date: "1990-01-01",
      gender: "female",
      marital_status: "single",
      children_count: 0,
      member_status: "active",
      official_membership_on: Date.current.to_s
    }
  end

  describe "POST /members (create) con ministerios" do
    it "crea las membresías de ministerio al crear el miembro" do
      post church_admin_members_path(church), params: {
        member: base_member_params,
        ministry_memberships_submitted: "1",
        ministry_memberships: {
          ministry1.public_id => { role: "member" },
          ministry2.public_id => { role: "leader" }
        }
      }
      member = church.members.last
      expect(response).to redirect_to(church_admin_member_path(church, member))
      expect(member.ministry_memberships.active.count).to eq(2)
      expect(member.ministry_memberships.find_by(ministry: ministry1).ministry_role).to eq("member")
      expect(member.ministry_memberships.find_by(ministry: ministry2).ministry_role).to eq("leader")
    end
  end

  describe "PATCH /members/:id (update) con ministerios" do
    let(:member) { create(:member, church:) }
    let!(:existing_mm) do
      create(:ministry_membership, member:, ministry: ministry1, status: "active", ministry_role: "member")
    end

    it "actualiza membresías al enviar la sección con datos" do
      patch church_admin_member_path(church, member), params: {
        member: base_member_params,
        ministry_memberships_submitted: "1",
        ministry_memberships: { ministry2.public_id => { role: "leader" } }
      }
      expect(existing_mm.reload.status).to eq("inactive")
      expect(member.ministry_memberships.active.count).to eq(1)
      expect(member.ministry_memberships.find_by(ministry: ministry2).ministry_role).to eq("leader")
    end

    it "desactiva todas las membresías cuando la sección se envía vacía" do
      patch church_admin_member_path(church, member), params: {
        member: base_member_params,
        ministry_memberships_submitted: "1"
      }
      expect(existing_mm.reload.status).to eq("inactive")
      expect(member.ministry_memberships.active).to be_empty
    end

    it "no toca las membresías si el sentinel está ausente" do
      patch church_admin_member_path(church, member), params: {
        member: base_member_params
      }
      expect(existing_mm.reload.status).to eq("active")
    end
  end

  describe "PATCH /members/:id — fix eliminar todas las ocupaciones" do
    let(:member)     { create(:member, church:) }
    let(:occupation) { create(:occupation, church:, status: "active") }
    let!(:member_occupation) do
      create(:member_occupation, member:, occupation:, church:)
    end

    it "elimina todas las ocupaciones cuando se envía la sección vacía" do
      patch church_admin_member_path(church, member), params: {
        member: base_member_params,
        occupation_section_submitted: "1"
      }
      expect(member.member_occupations.reload).to be_empty
    end
  end

  describe "PATCH /members/:id — fix eliminar todas las habilidades" do
    let(:member) { create(:member, church:) }
    let(:skill)  { create(:skill, church:, status: "active") }
    let!(:member_skill) { create(:member_skill, member:, skill:, church:) }

    it "elimina todas las habilidades cuando se envía la sección vacía" do
      patch church_admin_member_path(church, member), params: {
        member: base_member_params,
        skill_section_submitted: "1"
      }
      expect(member.member_skills.reload).to be_empty
    end
  end
end
