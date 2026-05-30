class Role < ApplicationRecord
  include ChurchScoped
  include PublicIdentifiable
  include PgSearch::Model
  has_paper_trail skip: %i[updated_at]

  pg_search_scope :search_by_name,
    against: :name,
    using: { tsearch: { prefix: true } }

  has_many :role_permissions, dependent: :destroy
  has_many :permissions, through: :role_permissions
  has_many :membership_roles, dependent: :destroy
  has_many :church_memberships, through: :membership_roles

  enum :status, { active: "active", inactive: "inactive" }, validate: true

  validates :name, presence: true, uniqueness: { scope: :church_id, case_sensitive: false }
  validates :status, presence: true
  validate :pastoral_permissions_require_pastoral_role

  normalizes :name, with: ->(name) { name.to_s.strip }

  def allows?(module_key, action_key)
    normalized_module = module_key.to_s
    normalized_actions = Permissions::PermissionChecker.permission_action_keys_for(action_key)

    permissions.where(module_key: normalized_module, action_key: normalized_actions).exists?
  end

  private

  def pastoral_permissions_require_pastoral_role
    return if pastoral?
    return unless permissions.where(module_key: "pastoral_notes").exists?

    errors.add(:pastoral, "debe estar activo para permisos pastorales")
  end
end
