module Platform
  class OwnerAssignment
    include ActiveModel::Model

    attr_accessor :church,
      :email,
      :first_name,
      :last_name,
      :password,
      :password_confirmation,
      :user,
      :membership

    validates :church, :email, presence: true
    validate :password_required_for_new_user

    def save
      return false unless valid?

      ActiveRecord::Base.transaction do
        assign_user!
        assign_membership!
      end

      true
    rescue ActiveRecord::RecordInvalid => error
      errors.add(:base, error.record.errors.full_messages.to_sentence)
      false
    end

    def persisted?
      false
    end

    def to_model
      self
    end

    private

    def assign_user!
      self.user = User.find_or_initialize_by(email: normalized_email)
      user.assign_attributes(user_attributes)
      assign_password if password.present?
      user.save!
    end

    def assign_membership!
      self.membership = ChurchMembership.find_or_initialize_by(church:, user:)
      membership.assign_attributes(owner: true, status: "active")
      membership.save!
    end

    def user_attributes
      {
        first_name: first_name.presence || user.first_name,
        last_name: last_name.presence || user.last_name,
        platform_role: user.platform_role.presence || "user",
        status: "active"
      }
    end

    def assign_password
      user.password = password
      user.password_confirmation = password_confirmation
    end

    def password_required_for_new_user
      return if normalized_email.blank?
      return if User.exists?(email: normalized_email)
      return if password.present?

      errors.add(:password, :blank)
    end

    def normalized_email
      email.to_s.strip.downcase
    end
  end
end
