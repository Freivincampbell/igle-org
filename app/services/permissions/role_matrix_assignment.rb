module Permissions
  class RoleMatrixAssignment
    include ActiveModel::Model

    attr_accessor :role, :permission_public_ids

    validates :role, presence: true
    validate :selected_permissions_exist

    def save
      return false unless valid?

      ActiveRecord::Base.transaction do
        role.role_permissions.where.not(permission_id: selected_permissions.map(&:id)).delete_all
        selected_permissions.each do |permission|
          role.role_permissions.find_or_create_by!(permission:)
        end
      end

      true
    rescue ActiveRecord::RecordInvalid => error
      errors.add(:base, error.record.errors.full_messages.to_sentence)
      false
    end

    private

    def selected_permissions
      @selected_permissions ||= Permission.assignable.where(public_id: normalized_permission_public_ids).to_a
    end

    def normalized_permission_public_ids
      Array(permission_public_ids).compact_blank.uniq
    end

    def selected_permissions_exist
      return if normalized_permission_public_ids.size == selected_permissions.size

      errors.add(:base, :invalid)
    end
  end
end
