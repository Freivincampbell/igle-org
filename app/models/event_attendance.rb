class EventAttendance < ApplicationRecord
  include ChurchScoped
  include PublicIdentifiable

  belongs_to :event
  belongs_to :member
  belongs_to :checked_in_by, class_name: "User", optional: true

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
