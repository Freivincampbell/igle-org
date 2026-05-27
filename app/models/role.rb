class Role < ApplicationRecord
  include ChurchScoped
  include PublicIdentifiable

  has_many :role_permissions, dependent: :destroy
  has_many :permissions, through: :role_permissions
  has_many :membership_roles, dependent: :destroy
  has_many :church_memberships, through: :membership_roles

  enum :status, { active: "active", inactive: "inactive" }, validate: true

  validates :name, presence: true, uniqueness: { scope: :church_id, case_sensitive: false }
  validates :status, presence: true

  normalizes :name, with: ->(name) { name.to_s.strip }

  def allows?(module_key, action_key)
    normalized_module = module_key.to_s
    normalized_action = action_key.to_s

    permissions.where(module_key: normalized_module, action_key: [ normalized_action, "manage" ]).exists?
  end
end
