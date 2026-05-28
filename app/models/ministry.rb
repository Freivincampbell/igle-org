class Ministry < ApplicationRecord
  include ChurchScoped
  include PublicIdentifiable

  has_many :ministry_memberships, dependent: :destroy
  has_many :members, through: :ministry_memberships
  has_many :events, dependent: :nullify

  enum :status, { active: "active", inactive: "inactive" }, validate: true

  normalizes :name, with: ->(name) { name.to_s.strip }

  validates :name, presence: true, uniqueness: { scope: :church_id, case_sensitive: false }
  validates :status, presence: true

  scope :ordered, -> { order(:name) }

  def active_ministry_memberships
    ministry_memberships.active.includes(:member)
  end
end
