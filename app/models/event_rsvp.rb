class EventRsvp < ApplicationRecord
  include ChurchScoped
  include PublicIdentifiable

  RSVP_STATUSES = %w[attending not_attending maybe].freeze

  belongs_to :event
  belongs_to :member

  enum :status, RSVP_STATUSES.index_with(&:itself), validate: true

  validates :guests_count, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validate :event_in_same_church
  validate :member_in_same_church

  private

  def event_in_same_church
    return if event.blank? || church.blank?
    return if event.church_id == church_id

    errors.add(:event, :must_belong_to_church)
  end

  def member_in_same_church
    return if member.blank? || church.blank?
    return if member.church_id == church_id

    errors.add(:member, :must_belong_to_church)
  end
end
