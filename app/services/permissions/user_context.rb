module Permissions
  UserContext = Data.define(:user, :current_church, :church_membership) do
    def self.build(user:, current_church:)
      new(
        user:,
        current_church:,
        church_membership: user&.active_membership_for(current_church)
      )
    end
  end
end
