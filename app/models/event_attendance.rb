class EventAttendance < ApplicationRecord
  include ChurchScoped
  include PublicIdentifiable
  has_paper_trail skip: %i[updated_at]

  belongs_to :event
  belongs_to :member, optional: true
  belongs_to :checked_in_by, class_name: "User", optional: true

  normalizes :guest_name, with: ->(value) { value.to_s.strip.presence }

  before_validation :assign_occurrence_date, on: :create

  validate :member_or_guest_present
  validate :event_in_same_church
  validate :member_in_same_church

  scope :present, -> { where(attended: true) }

  def attendee_name
    member&.full_name || guest_name
  end

  private

  def assign_occurrence_date
    self.occurrence_date ||= event&.starts_at&.to_date
  end

  def member_or_guest_present
    return if member.present? || guest_name.present?

    errors.add(:base, :attendee_required)
  end

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
