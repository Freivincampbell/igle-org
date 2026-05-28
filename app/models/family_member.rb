class FamilyMember < ApplicationRecord
  include ChurchScoped
  include PublicIdentifiable

  RELATIONSHIPS = %w[spouse child parent guardian sibling other].freeze

  belongs_to :family
  belongs_to :member

  enum :relationship, RELATIONSHIPS.index_with(&:itself), prefix: :as, validate: true

  validates :member_id, uniqueness: { scope: :family_id }
  validate :family_in_same_church
  validate :member_in_same_church

  private

  def family_in_same_church
    return if family.blank? || church.blank?
    return if family.church_id == church_id

    errors.add(:family, :must_belong_to_church)
  end

  def member_in_same_church
    return if member.blank? || church.blank?
    return if member.church_id == church_id

    errors.add(:member, :must_belong_to_church)
  end
end
