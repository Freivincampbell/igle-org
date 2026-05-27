module Permissions
  class MembershipRoleAssignment
    include ActiveModel::Model

    attr_accessor :church_membership, :role_public_ids

    validates :church_membership, presence: true
    validate :selected_roles_exist

    def save
      return false unless valid?

      ActiveRecord::Base.transaction do
        church_membership.membership_roles.where.not(role_id: selected_roles.map(&:id)).delete_all
        selected_roles.each do |role|
          church_membership.membership_roles.find_or_create_by!(role:)
        end
      end

      true
    rescue ActiveRecord::RecordInvalid => error
      errors.add(:base, error.record.errors.full_messages.to_sentence)
      false
    end

    private

    def selected_roles
      @selected_roles ||= church_membership.church.roles.where(public_id: normalized_role_public_ids).to_a
    end

    def normalized_role_public_ids
      Array(role_public_ids).compact_blank.uniq
    end

    def selected_roles_exist
      return if normalized_role_public_ids.size == selected_roles.size

      errors.add(:base, :invalid)
    end
  end
end
