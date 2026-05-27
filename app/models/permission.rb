class Permission < ApplicationRecord
  ACTION_KEYS = %w[read create update activate deactivate export manage].freeze
  MODULE_KEYS = %w[
    churches
    church_memberships
    users
    roles
    permissions
    members
    ministries
    board
    events
    reports
    settings
    pastoral_notes
  ].freeze

  has_many :role_permissions, dependent: :destroy
  has_many :roles, through: :role_permissions

  validates :module_key, presence: true, inclusion: { in: MODULE_KEYS }
  validates :action_key, presence: true, inclusion: { in: ACTION_KEYS }
  validates :name, presence: true
  validates :module_key, uniqueness: { scope: :action_key }

  scope :ordered, -> { order(:position, :module_key, :action_key) }
end
