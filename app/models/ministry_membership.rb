class MinistryMembership < ApplicationRecord
  include PublicIdentifiable

  belongs_to :ministry
  belongs_to :member

  enum :ministry_role, { member: "member", leader: "leader", co_leader: "co_leader" }, validate: true
  enum :status, { active: "active", inactive: "inactive" }, validate: true

  validates :member_id, uniqueness: { scope: :ministry_id }
  validates :ministry_role, :status, presence: true
  validate :member_belongs_to_ministry_church

  scope :ordered, -> { joins(:member).order("members.last_name", "members.second_last_name", "members.first_name") }

  private

  def member_belongs_to_ministry_church
    return if member.blank? || ministry.blank?
    return if member.church_id == ministry.church_id

    errors.add(:member, "must belong to the same church as the ministry")
  end
end
