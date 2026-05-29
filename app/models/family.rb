class Family < ApplicationRecord
  include ChurchScoped
  include PublicIdentifiable

  has_many :family_members, dependent: :destroy
  has_many :members, through: :family_members
  has_many :addresses, as: :addressable, dependent: :destroy

  enum :status, { active: "active", inactive: "inactive" }, validate: true

  normalizes :name, with: ->(value) { value.to_s.strip }

  validates :name, presence: true
  validates :status, presence: true

  scope :ordered, -> { order(:name) }

  def primary_address
    addresses.first
  end
end
