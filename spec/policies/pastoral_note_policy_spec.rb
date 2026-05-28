require "rails_helper"

RSpec.describe PastoralNotePolicy do
  let(:church) { create(:church) }
  let(:note) { create(:pastoral_note, church:) }

  before { Current.church = church }
  after { Current.church = nil; Current.church_membership = nil }

  def membership_with_pastoral_role(pastoral:, permission_action: "read")
    membership = create(:church_membership, church:)
    role = create(:role, church:, pastoral: pastoral)
    create(:membership_role, church_membership: membership, role:)
    permission = Permission.find_or_create_by!(module_key: "pastoral_notes", action_key: permission_action) do |p|
      p.name = "Notas pastorales #{permission_action}"
    end
    create(:role_permission, role:, permission:)
    Current.church_membership = membership
    membership
  end

  it "denies access without any pastoral role even with permission" do
    pending_pr = nil
    expect {
      pending_pr = membership_with_pastoral_role(pastoral: false)
    }.to raise_error(ActiveRecord::RecordInvalid, /pastoral role/)
  end

  it "owner without pastoral role cannot access pastoral notes" do
    membership = create(:church_membership, :owner, church:)
    Current.church_membership = membership

    expect(PastoralNotePolicy.new(membership.user, note).index?).to be(false)
    expect(PastoralNotePolicy.new(membership.user, note).show?).to be(false)
  end

  it "pastoral role with read permission can index and show but not create" do
    membership = membership_with_pastoral_role(pastoral: true, permission_action: "read")

    expect(PastoralNotePolicy.new(membership.user, note).index?).to be(true)
    expect(PastoralNotePolicy.new(membership.user, note).show?).to be(true)
    expect(PastoralNotePolicy.new(membership.user, note).create?).to be(false)
  end

  it "pastoral role with create permission can create and update" do
    membership = membership_with_pastoral_role(pastoral: true, permission_action: "create")

    expect(PastoralNotePolicy.new(membership.user, note).create?).to be(true)
    expect(PastoralNotePolicy.new(membership.user, note).update?).to be(true)
  end

  it "pastoral role with manage permission can destroy" do
    membership = membership_with_pastoral_role(pastoral: true, permission_action: "manage")

    expect(PastoralNotePolicy.new(membership.user, note).destroy?).to be(true)
  end
end
