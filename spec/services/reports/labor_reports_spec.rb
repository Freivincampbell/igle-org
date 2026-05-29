require "rails_helper"

RSpec.describe "Reportes laborales" do
  let(:church) { create(:church) }

  describe Reports::MembersByOccupationReport do
    it "lista ocupaciones de miembros scopeadas por iglesia y filtra por occupation_id" do
      occ = create(:occupation, church:, name: "Carpintero")
      member = create(:member, church:, first_name: "Pedro")
      create(:member_occupation, church:, member:, occupation: occ, job_title: "Maestro")

      other = create(:member_occupation)

      rows = described_class.new(church:, filters: { occupation_id: occ.id }).rows

      expect(rows.size).to eq(1)
      expect(rows.first[:occupation]).to eq("Carpintero")
      expect(rows.first[:member]).to eq(member.full_name)
      expect(rows.map { |r| r[:member] }).not_to include(other.member.full_name)
    end
  end

  describe Reports::MembersBySkillReport do
    it "lista habilidades de miembros con nivel, scopeadas por iglesia" do
      skill = create(:skill, church:, name: "Sonido")
      member = create(:member, church:, first_name: "Lucas")
      create(:member_skill, church:, member:, skill:, level: "advanced")

      rows = described_class.new(church:, filters: { skill_id: skill.id }).rows

      expect(rows.size).to eq(1)
      expect(rows.first[:skill]).to eq("Sonido")
      expect(rows.first[:member]).to eq(member.full_name)
    end
  end

  describe Reports::JobSeekersReport do
    it "lista solo quienes buscan trabajo" do
      seeker_member = create(:member, church:, first_name: "Busca")
      create(:member_occupation, church:, member: seeker_member, looking_for_work: true)
      other_member = create(:member, church:, first_name: "NoBusca")
      create(:member_occupation, church:, member: other_member, looking_for_work: false)

      rows = described_class.new(church:).rows

      expect(rows.map { |r| r[:member] }).to contain_exactly(seeker_member.full_name)
    end
  end

  describe Reports::ServiceProvidersReport do
    it "lista solo quienes ofrecen servicios" do
      provider_member = create(:member, church:, first_name: "Ofrece")
      create(:member_occupation, church:, member: provider_member, offers_services: true)
      other_member = create(:member, church:, first_name: "NoOfrece")
      create(:member_occupation, church:, member: other_member, offers_services: false)

      rows = described_class.new(church:).rows

      expect(rows.map { |r| r[:member] }).to contain_exactly(provider_member.full_name)
    end
  end
end
