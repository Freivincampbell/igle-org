require "rails_helper"

RSpec.describe ChurchSettingPolicy do
  let(:church) { create(:church) }

  before do
    Current.church = church
  end

  after do
    Current.church = nil
    Current.church_membership = nil
  end

  def grant(action_key)
    permission = Permission.find_or_create_by!(module_key: "church_settings", action_key:) do |perm|
      perm.name = "church_settings #{action_key}"
    end
    permission
  end

  def membership_with(role:)
    membership = create(:church_membership, church:)
    Current.church_membership = membership
    create(:membership_role, church_membership: membership, role:)
    membership
  end

  it "denies show without permission" do
    membership = create(:church_membership, church:)
    Current.church_membership = membership

    expect(ChurchSettingPolicy.new(membership.user, church).show?).to be(false)
  end

  it "allows show with read permission" do
    role = create(:role, church:)
    create(:role_permission, role:, permission: grant("read"))
    membership = membership_with(role:)

    expect(ChurchSettingPolicy.new(membership.user, church).show?).to be(true)
  end

  it "denies update with only read permission" do
    role = create(:role, church:)
    create(:role_permission, role:, permission: grant("read"))
    membership = membership_with(role:)

    expect(ChurchSettingPolicy.new(membership.user, church).update?).to be(false)
  end

  it "allows update with create permission" do
    role = create(:role, church:)
    create(:role_permission, role:, permission: grant("create"))
    membership = membership_with(role:)

    expect(ChurchSettingPolicy.new(membership.user, church).update?).to be(true)
  end

  it "owner bootstrap allows all settings actions" do
    membership = create(:church_membership, :owner, church:)
    Current.church_membership = membership

    expect(ChurchSettingPolicy.new(membership.user, church).show?).to be(true)
    expect(ChurchSettingPolicy.new(membership.user, church).update?).to be(true)
  end
end
