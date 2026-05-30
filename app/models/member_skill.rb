class MemberSkill < ApplicationRecord
  include ChurchScoped
  include PublicIdentifiable

  LEVELS = %w[basic intermediate advanced professional].freeze

  belongs_to :member
  belongs_to :skill

  enum :level, LEVELS.index_with(&:itself), validate: true

  scope :offering_service, -> { where(offers_service: true) }

  validate :member_in_same_church
  validate :skill_in_same_church

  private

  def member_in_same_church
    return if member.blank? || church.blank?
    return if member.church_id == church_id

    errors.add(:member, :must_belong_to_church)
  end

  def skill_in_same_church
    return if skill.blank? || church.blank?
    return if skill.church_id == church_id

    errors.add(:skill, :must_belong_to_church)
  end
end
