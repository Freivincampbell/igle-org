class ChurchMembership < ApplicationRecord
  include ChurchScoped
  include PublicIdentifiable
  has_paper_trail skip: %i[updated_at]

  belongs_to :user
  has_many :membership_roles, dependent: :destroy
  has_many :roles, through: :membership_roles

  enum :status, { active: "active", inactive: "inactive" }, validate: true

  validates :user, presence: true
  validates :user_id, uniqueness: { scope: :church_id }
  validates :status, presence: true
  validate :roles_belong_to_membership_church

  before_validation :set_joined_at, on: :create

  def has_permission?(module_key, action_key)
    Permissions::PermissionChecker.allow?(
      user_context: Permissions::UserContext.new(
        user:,
        current_church: church,
        church_membership: self
      ),
      module_key:,
      action: action_key
    )
  end

  private

  def set_joined_at
    self.joined_at ||= Time.current
  end

  def roles_belong_to_membership_church
    roles.each do |role|
      errors.add(:roles, "must belong to the same church") if role.church_id != church_id
    end
  end
end
