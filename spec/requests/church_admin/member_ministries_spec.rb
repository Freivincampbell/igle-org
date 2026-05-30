require "rails_helper"

RSpec.describe "ChurchAdmin::MemberMinistries", type: :request do
  let(:church)     { create(:church) }
  let(:membership) { create(:church_membership, :owner, church:) }
  let(:member)     { create(:member, church:) }
  let(:ministry1)  { create(:ministry, church:, status: "active") }
  let(:ministry2)  { create(:ministry, church:, status: "active") }

  before { sign_in membership.user }

  def assign_path
    assign_ministries_church_admin_member_path(church, member)
  end

  describe "PATCH /assign_ministries" do
    context "cuando se asignan ministerios nuevos" do
      it "crea las membresías y redirige con aviso" do
        patch assign_path, params: {
          ministry_memberships: {
            ministry1.public_id => { role: "member" },
            ministry2.public_id => { role: "leader" }
          }
        }
        expect(response).to redirect_to(church_admin_member_path(church, member))
        follow_redirect!
        expect(response.body).to include(I18n.t("church_admin.member_ministries.updated"))
        expect(member.ministry_memberships.active.count).to eq(2)
        expect(member.ministry_memberships.find_by(ministry: ministry1).ministry_role).to eq("member")
        expect(member.ministry_memberships.find_by(ministry: ministry2).ministry_role).to eq("leader")
      end
    end

    context "cuando se actualiza el rol de una membresía existente" do
      let!(:existing_mm) do
        create(:ministry_membership, member:, ministry: ministry1,
               status: "active", ministry_role: "member")
      end

      it "actualiza el rol sin duplicar la membresía" do
        patch assign_path, params: {
          ministry_memberships: { ministry1.public_id => { role: "leader" } }
        }
        expect(member.ministry_memberships.active.count).to eq(1)
        expect(existing_mm.reload.ministry_role).to eq("leader")
      end
    end

    context "cuando se desasigna un ministerio (no está en la lista enviada)" do
      let!(:existing_mm) do
        create(:ministry_membership, member:, ministry: ministry1,
               status: "active", ministry_role: "member")
      end

      it "desactiva la membresía sin borrarla físicamente" do
        patch assign_path, params: { ministry_memberships: {} }
        expect(existing_mm.reload.status).to eq("inactive")
      end

      it "no destruye el registro" do
        expect {
          patch assign_path, params: { ministry_memberships: {} }
        }.not_to change(MinistryMembership, :count)
      end
    end

    context "cuando el ministerio pertenece a otra iglesia" do
      let(:foreign_ministry) { create(:ministry, status: "active") }

      it "redirige con alerta sin crear membresías" do
        patch assign_path, params: {
          ministry_memberships: { foreign_ministry.public_id => { role: "member" } }
        }
        expect(response).to redirect_to(church_admin_member_path(church, member))
        follow_redirect!
        expect(response.body).to include(I18n.t("church_admin.member_ministries.invalid_ministry"))
        expect(member.ministry_memberships.active).to be_empty
      end
    end

    context "aislamiento multi-tenant" do
      let(:church2)         { create(:church) }
      let(:ministry_other)  { create(:ministry, church: church2, status: "active") }

      it "no puede asignar un ministerio de otra iglesia" do
        patch assign_path, params: {
          ministry_memberships: { ministry_other.public_id => { role: "member" } }
        }
        follow_redirect!
        expect(response.body).to include(I18n.t("church_admin.member_ministries.invalid_ministry"))
        expect(member.ministry_memberships.active).to be_empty
      end
    end

    context "cuando el usuario no tiene permiso de editar miembros" do
      let(:other_membership) { create(:church_membership, church:) }

      before { sign_in other_membership.user }

      it "redirige con alerta de no autorizado" do
        patch assign_path, params: { ministry_memberships: {} }
        expect(flash[:alert]).to eq(I18n.t("authorization.not_authorized"))
      end
    end
  end
end
