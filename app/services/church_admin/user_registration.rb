module ChurchAdmin
  class UserRegistration
    include ActiveModel::Model

    attr_accessor :church,
      :email,
      :first_name,
      :last_name,
      :initial_access,
      :initial_access_confirmation,
      :role_public_ids,
      :user,
      :membership

    validates :church, :email, presence: true
    validate :initial_access_required_for_new_user
    validate :user_must_not_belong_to_church
    validate :selected_roles_must_belong_to_church

    def save
      return false unless valid?

      ActiveRecord::Base.transaction do
        assign_user!
        assign_membership!
        assign_roles!
      end

      true
    rescue ActiveRecord::RecordInvalid => error
      merge_record_errors(error.record)
      false
    end

    def persisted?
      false
    end

    def to_model
      self
    end

    def role_public_ids
      Array(@role_public_ids).compact_blank.uniq
    end

    private

    def assign_user!
      self.user = existing_user || User.new(email: normalized_email)

      user.assign_attributes(user_attributes)
      assign_initial_access if user.new_record?
      user.save!
    end

    def assign_membership!
      self.membership = church.church_memberships.create!(
        user:,
        owner: false,
        status: "active"
      )
    end

    def assign_roles!
      selected_roles.each do |role|
        membership.membership_roles.create!(role:)
      end
    end

    def user_attributes
      if existing_user
        {
          first_name: first_name.presence || existing_user.first_name,
          last_name: last_name.presence || existing_user.last_name
        }
      else
        {
          first_name:,
          last_name:,
          platform_role: "user",
          status: "active"
        }
      end
    end

    def assign_initial_access
      user.password = initial_access
      user.password_confirmation = initial_access_confirmation
    end

    def existing_user
      @existing_user ||= User.find_by(email: normalized_email)
    end

    def selected_roles
      @selected_roles ||= church.roles.active.where(public_id: role_public_ids).to_a
    end

    def normalized_email
      email.to_s.strip.downcase
    end

    def initial_access_required_for_new_user
      return if normalized_email.blank?
      return if existing_user.present?
      return if initial_access.present?

      errors.add(:initial_access, :blank)
    end

    def user_must_not_belong_to_church
      return if church.blank? || existing_user.blank?
      return unless church.church_memberships.exists?(user: existing_user)

      errors.add(:email, :taken)
    end

    def selected_roles_must_belong_to_church
      return if church.blank?
      return if role_public_ids.size == selected_roles.size

      errors.add(:base, :invalid)
    end

    def merge_record_errors(record)
      record.errors.each do |error|
        errors.add(error.attribute, error.type, **error.options)
      end
    end
  end
end
