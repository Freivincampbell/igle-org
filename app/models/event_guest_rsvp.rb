class EventGuestRsvp < ApplicationRecord
  include ChurchScoped
  include PublicIdentifiable
  has_paper_trail skip: %i[updated_at]

  GUEST_RSVP_STATUSES = %w[attending cancelled].freeze

  belongs_to :event

  has_secure_token :access_token

  enum :status, GUEST_RSVP_STATUSES.index_with(&:itself), validate: true

  normalizes :name, with: ->(value) { value.to_s.strip.presence }
  normalizes :email, with: ->(value) { value.to_s.strip.downcase.presence }
  normalizes :phone, with: ->(value) { value.to_s.strip.presence }

  validates :name, presence: true
  validates :guests_count, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validate :email_or_phone_present
  validate :event_in_same_church

  private

  def email_or_phone_present
    return if email.present? || phone.present?

    errors.add(:base, :contact_required)
  end

  def event_in_same_church
    return if event.blank? || church.blank?
    return if event.church_id == church_id

    errors.add(:event, :must_belong_to_church)
  end
end
