class Occupation < ApplicationRecord
  include ChurchScoped
  include PublicIdentifiable

  has_many :member_occupations, dependent: :destroy
  has_many :members, through: :member_occupations

  enum :status, { active: "active", inactive: "inactive" }, validate: true

  normalizes :name, with: ->(value) { value.to_s.strip }

  validates :name, presence: true, uniqueness: { scope: :church_id, case_sensitive: false }
  validates :status, presence: true

  scope :ordered, -> { order(:name) }
end
