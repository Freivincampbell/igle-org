class ChurchServiceTime < ApplicationRecord
  include ChurchScoped
  include PublicIdentifiable
  include PgSearch::Model

  pg_search_scope :search_by_name,
    against: :name,
    using: { tsearch: { prefix: true } }

  DAYS_OF_WEEK = (0..6).to_a.freeze

  enum :status, { active: "active", inactive: "inactive" }, validate: true

  normalizes :name, :location, with: ->(value) { value.to_s.strip.presence }

  validates :name, presence: true
  validates :day_of_week, presence: true, inclusion: { in: DAYS_OF_WEEK }
  validates :starts_at, presence: true
  validate :ends_at_after_starts_at

  scope :ordered, -> { order(:day_of_week, :starts_at, :name) }

  def day_name
    I18n.t("date.day_names")[day_of_week]
  end

  private

  def ends_at_after_starts_at
    return if ends_at.blank? || starts_at.blank?
    return if ends_at > starts_at

    errors.add(:ends_at, :must_be_after_starts_at)
  end
end
