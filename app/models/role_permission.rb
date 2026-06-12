class RolePermission < ApplicationRecord
  include PublicIdentifiable
  has_paper_trail skip: %i[updated_at]

  belongs_to :role
  belongs_to :permission

  SCOPES = %w[own assigned_ministry church].freeze
  enum :scope, SCOPES.index_with(&:itself), default: "church", validate: true

  validates :permission_id, uniqueness: { scope: :role_id }
  validate :pastoral_permission_requires_pastoral_role

  private

  def pastoral_permission_requires_pastoral_role
    return if role.blank? || permission.blank?
    return unless permission.module_key == "pastoral_notes"
    return if role.pastoral?

    errors.add(:permission, "requires a pastoral role")
  end
end
