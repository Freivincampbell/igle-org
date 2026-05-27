class MembershipRole < ApplicationRecord
  include PublicIdentifiable

  belongs_to :church_membership
  belongs_to :role

  validates :role_id, uniqueness: { scope: :church_membership_id }
  validate :role_belongs_to_membership_church

  private

  def role_belongs_to_membership_church
    return if role.blank? || church_membership.blank?
    return if role.church_id == church_membership.church_id

    errors.add(:role, "must belong to the same church as the membership")
  end
end
