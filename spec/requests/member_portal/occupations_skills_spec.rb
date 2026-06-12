require "rails_helper"

RSpec.describe "Member portal occupations and skills" do
  def member_in_church
    church = create(:church)
    user = create(:user)
    create(:church_membership, church:, user:)
    member = create(:member, church:, user:)
    [ church, user, member ]
  end

  it "el perfil renderiza las secciones de ocupaciones y habilidades con lo agregado" do
    church, user, member = member_in_church
    create(:member_occupation, church:, member:, occupation: create(:occupation, church:, name: "Plomero"))
    create(:member_skill, church:, member:, skill: create(:skill, church:, name: "Bajo"), level: "advanced")
    sign_in user

    get church_member_portal_profile_path(church)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Mis ocupaciones")
    expect(response.body).to include("Plomero")
    expect(response.body).to include("Mis habilidades")
    expect(response.body).to include("Bajo")
  end

  describe "ocupaciones" do
    it "agrega una ocupación al propio perfil (sin aprobación)" do
      church, user, member = member_in_church
      sign_in user

      expect {
        post church_member_portal_occupations_path(church), params: { occupation_name: "Carpintero", offers_services: "1" }
      }.to change { member.member_occupations.count }.by(1)

      mo = member.member_occupations.last
      expect(mo.occupation.name).to eq("Carpintero")
      expect(mo.offers_services).to be(true)
      expect(response).to redirect_to(church_member_portal_profile_path(church))
    end

    it "no crea nada sin nombre" do
      church, user, _member = member_in_church
      sign_in user

      expect {
        post church_member_portal_occupations_path(church), params: { occupation_name: "  " }
      }.not_to change(MemberOccupation, :count)
    end

    it "reutiliza la ocupación existente del catálogo de la iglesia" do
      church, user, member = member_in_church
      occupation = create(:occupation, church:, name: "Docente")
      sign_in user

      expect {
        post church_member_portal_occupations_path(church), params: { occupation_name: "Docente" }
      }.not_to change(Occupation, :count)

      expect(member.member_occupations.last.occupation).to eq(occupation)
    end

    it "quita una ocupación propia" do
      church, user, member = member_in_church
      mo = create(:member_occupation, church:, member:)
      sign_in user

      expect {
        delete church_member_portal_occupation_path(church, mo.public_id)
      }.to change { member.member_occupations.count }.by(-1)
    end

    it "no permite quitar la ocupación de otro miembro (aislamiento)" do
      church, user, _member = member_in_church
      other = create(:member, church:)
      other_mo = create(:member_occupation, church:, member: other)
      sign_in user

      delete church_member_portal_occupation_path(church, other_mo.public_id)

      expect(response).to have_http_status(:not_found)
      expect { other_mo.reload }.not_to raise_error
    end
  end

  describe "habilidades" do
    it "agrega una habilidad propia con nivel" do
      church, user, member = member_in_church
      sign_in user

      expect {
        post church_member_portal_skills_path(church), params: { skill_name: "Guitarra", level: "intermediate", offers_service: "1" }
      }.to change { member.member_skills.count }.by(1)

      ms = member.member_skills.last
      expect(ms.skill.name).to eq("Guitarra")
      expect(ms.level).to eq("intermediate")
      expect(ms.offers_service).to be(true)
    end

    it "quita una habilidad propia" do
      church, user, member = member_in_church
      ms = create(:member_skill, church:, member:)
      sign_in user

      expect {
        delete church_member_portal_skill_path(church, ms.public_id)
      }.to change { member.member_skills.count }.by(-1)
    end
  end
end
