require "rails_helper"

RSpec.describe "Pastor pastoral notes" do
  def grant_pastoral(church, action: "manage")
    membership = create(:church_membership, church:)
    role = create(:role, church:, pastoral: true)
    create(:membership_role, church_membership: membership, role:)
    permission = Permission.find_or_create_by!(module_key: "pastoral_notes", action_key: action) do |p|
      p.name = "Notas pastorales #{action}"
    end
    create(:role_permission, role:, permission:)
    membership
  end

  it "denies access to owner without pastoral role" do
    church = create(:church)
    owner = create(:church_membership, :owner, church:)
    sign_in owner.user

    get church_pastor_pastoral_notes_path(church)

    expect(response).to redirect_to(root_path)
  end

  it "renders member options using public_id, not the internal id" do
    church = create(:church)
    member = create(:member, church:, first_name: "Ana", last_name: "Lopez", second_last_name: "Diaz")
    pastoral_membership = grant_pastoral(church)
    sign_in pastoral_membership.user

    get new_church_pastor_pastoral_note_path(church)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(%(<option value="#{member.public_id}">#{member.full_name}</option>))
    expect(response.body).not_to include(%(<option value="#{member.id}">#{member.full_name}</option>))
  end

  it "allows pastor to create a note resolving the member by public_id" do
    church = create(:church)
    member = create(:member, church:)
    pastoral_membership = grant_pastoral(church)
    sign_in pastoral_membership.user

    expect do
      post church_pastor_pastoral_notes_path(church), params: {
        pastoral_note: { member_public_id: member.public_id, title: "Visita", body: "Conversamos", note_type: "general" }
      }
    end.to change(PastoralNote, :count).by(1)

    expect(PastoralNote.last.member).to eq(member)
  end

  it "allows pastor to update the member by public_id" do
    church = create(:church)
    member_a = create(:member, church:)
    member_b = create(:member, church:)
    pastoral_membership = grant_pastoral(church)
    note = create(:pastoral_note, church:, member: member_a, pastor: pastoral_membership.user)
    sign_in pastoral_membership.user

    patch church_pastor_pastoral_note_path(church, note), params: {
      pastoral_note: { member_public_id: member_b.public_id, title: "Visita", body: "Conversamos", note_type: "general" }
    }

    expect(note.reload.member).to eq(member_b)
  end

  it "isolates notes per church" do
    church_a = create(:church)
    church_b = create(:church)
    member_a = create(:member, church: church_a, first_name: "Pastoral1")
    member_b = create(:member, church: church_b, first_name: "Pastoral2")
    create(:pastoral_note, church: church_a, member: member_a)
    create(:pastoral_note, church: church_b, member: member_b)
    pastoral = grant_pastoral(church_a)
    sign_in pastoral.user

    get church_pastor_pastoral_notes_path(church_a)

    expect(response.body).to include(member_a.full_name)
    expect(response.body).not_to include(member_b.full_name)
  end
end
