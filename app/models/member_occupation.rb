class MemberOccupation < ApplicationRecord
  include ChurchScoped
  include PublicIdentifiable

  EMPLOYMENT_STATUSES = %w[employed unemployed self_employed student retired homemaker looking_for_work].freeze
  WORK_TYPES = %w[full_time part_time freelance temporary volunteer].freeze

  belongs_to :member
  belongs_to :occupation, optional: true

  enum :employment_status, EMPLOYMENT_STATUSES.index_with(&:itself), prefix: :emp, validate: true
  enum :work_type, WORK_TYPES.index_with(&:itself), prefix: :work, allow_nil: true

  normalizes :company_name, :job_title, :professional_contact, :profile_url,
             with: ->(value) { value.to_s.strip.presence }

  validate :member_in_same_church
  validate :occupation_in_same_church

  private

  def member_in_same_church
    return if member.blank? || church.blank?
    return if member.church_id == church_id

    errors.add(:member, :must_belong_to_church)
  end

  def occupation_in_same_church
    return if occupation.blank? || church.blank?
    return if occupation.church_id == church_id

    errors.add(:occupation, :must_belong_to_church)
  end
end
