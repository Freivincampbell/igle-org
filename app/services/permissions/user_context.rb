module Permissions
  UserContext = Data.define(:user, :current_church, :church_membership) do
    def self.build(user:, current_church:)
      new(
        user:,
        current_church:,
        church_membership: user&.active_membership_for(current_church)
      )
    end

    def membership_roles
      church_membership&.roles&.active || Role.none
    end

    def assigned_ministry_ids
      return [] if user.blank? || current_church.blank?

      member = Member.find_by(user:, church: current_church)
      return [] unless member

      Ministry.joins(:ministry_memberships)
        .where(ministry_memberships: { member:, ministry_role: %w[leader co_leader], status: "active" })
        .ids
    end
  end
end
