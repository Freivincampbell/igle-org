class ProfileChangeRequest < ApplicationRecord
  include ChurchScoped
  include PublicIdentifiable

  ALLOWED_ATTRIBUTES = %w[
    first_name middle_name last_name second_last_name
    email phone secondary_phone
    marital_status address_line_1 address_line_2 city state postal_code country
    emergency_contact_name emergency_contact_phone
  ].freeze

  enum :status, { pending: "pending", approved: "approved", rejected: "rejected" }, validate: true

  belongs_to :member
  belongs_to :requested_by, class_name: "User", optional: true
  belongs_to :reviewed_by, class_name: "User", optional: true

  validates :changes_payload, presence: true
  validate :payload_has_allowed_keys

  scope :ordered, -> { order(created_at: :desc) }

  def filtered_changes
    (changes_payload || {}).slice(*ALLOWED_ATTRIBUTES)
  end

  def approve!(reviewer:, notes: nil)
    return false unless pending?

    ActiveRecord::Base.transaction do
      member.update!(filtered_changes)
      update!(status: "approved", reviewed_by: reviewer, reviewed_at: Time.current, review_notes: notes)
    end
    true
  end

  def reject!(reviewer:, notes: nil)
    return false unless pending?

    update!(status: "rejected", reviewed_by: reviewer, reviewed_at: Time.current, review_notes: notes)
  end

  private

  def payload_has_allowed_keys
    return if changes_payload.blank?
    return if (changes_payload.keys.map(&:to_s) - ALLOWED_ATTRIBUTES).empty?

    errors.add(:changes_payload, :contains_disallowed_keys)
  end
end
