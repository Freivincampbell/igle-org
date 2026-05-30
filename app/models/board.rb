class Board < ApplicationRecord
  include ChurchScoped
  include PublicIdentifiable
  include PgSearch::Model

  pg_search_scope :search_by_name,
    against: :name,
    using: { tsearch: { prefix: true } }

  has_many :board_members, dependent: :destroy
  has_many :members, through: :board_members

  enum :status, { active: "active", inactive: "inactive" }, validate: true

  normalizes :name, with: ->(value) { value.to_s.strip }

  validates :name, presence: true
  validates :starts_on, presence: true
  validate :ends_on_after_starts_on

  scope :ordered, -> { order(starts_on: :desc) }
  scope :current, -> { where(status: "active") }

  private

  def ends_on_after_starts_on
    return if ends_on.blank? || starts_on.blank?
    return if ends_on > starts_on

    errors.add(:ends_on, :must_be_after_starts_on)
  end
end
