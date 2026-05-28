class Permission < ApplicationRecord
  include PublicIdentifiable

  ACTION_KEYS = %w[read create manage].freeze
  MODULE_KEYS = %w[
    church_memberships
    roles
    members
    ministries
    families
    boards
    events
    occupations
    skills
    profile_change_requests
    reports
    church_settings
    pastoral_notes
  ].freeze
  ASSIGNABLE_MODULE_KEYS = %w[
    church_memberships
    roles
    members
    ministries
    events
    church_settings
    pastoral_notes
  ].freeze

  has_many :role_permissions, dependent: :destroy
  has_many :roles, through: :role_permissions

  validates :module_key, presence: true, inclusion: { in: MODULE_KEYS }
  validates :action_key, presence: true, inclusion: { in: ACTION_KEYS }
  validates :name, presence: true
  validates :module_key, uniqueness: { scope: :action_key }

  scope :assignable, -> { where(module_key: ASSIGNABLE_MODULE_KEYS, action_key: ACTION_KEYS) }
  scope :ordered, -> { order(:position, :module_key, :action_key) }
end
