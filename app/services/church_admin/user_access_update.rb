module ChurchAdmin
  class UserAccessUpdate
    include ActiveModel::Model

    attr_accessor :church_membership, :user_attributes, :role_public_ids

    validates :church_membership, presence: true
    validate :selected_roles_must_belong_to_church

    def save
      return false unless valid?

      ActiveRecord::Base.transaction do
        update_user!
        sync_roles!
      end

      true
    rescue ActiveRecord::RecordInvalid => error
      merge_record_errors(error.record)
      false
    end

    def role_public_ids
      Array(@role_public_ids).compact_blank.uniq
    end

    private

    def update_user!
      user.assign_attributes(normalized_user_attributes)
      user.save!
    end

    def sync_roles!
      church_membership.membership_roles.where.not(role_id: selected_roles.map(&:id)).delete_all
      selected_roles.each do |role|
        church_membership.membership_roles.find_or_create_by!(role:)
      end
    end

    def normalized_user_attributes
      attributes = user_attributes.to_h.symbolize_keys.slice(
        :first_name,
        :last_name,
        :email,
        :access_code,
        :access_code_confirmation
      )

      access_code = attributes.delete(:access_code)
      access_code_confirmation = attributes.delete(:access_code_confirmation)
      return attributes if access_code.blank? && access_code_confirmation.blank?

      attributes.merge(password: access_code, password_confirmation: access_code_confirmation)
    end

    def selected_roles
      @selected_roles ||= church.roles.active.where(public_id: role_public_ids).to_a
    end

    def selected_roles_must_belong_to_church
      return if church_membership.blank?
      return if role_public_ids.size == selected_roles.size

      errors.add(:base, :invalid)
    end

    def user
      church_membership.user
    end

    def church
      church_membership.church
    end

    def merge_record_errors(record)
      record.errors.each do |error|
        errors.add(error.attribute, error.type, **error.options)
      end
    end
  end
end
