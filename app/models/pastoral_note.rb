class PastoralNote < ApplicationRecord
  include ChurchScoped
  include PublicIdentifiable
  has_paper_trail skip: %i[updated_at]

  NOTE_TYPES = %w[general counseling follow_up prayer].freeze

  belongs_to :member
  belongs_to :pastor, class_name: "User"

  enum :note_type, NOTE_TYPES.index_with(&:itself), validate: true

  normalizes :title, with: ->(value) { value.to_s.strip.presence }

  validates :body, presence: true
  validate :member_in_same_church

  scope :ordered, -> { order(created_at: :desc) }

  def member_public_id
    member&.public_id
  end

  private

  def member_in_same_church
    return if member.blank? || church.blank?
    return if member.church_id == church_id

    errors.add(:member, :must_belong_to_church)
  end
end
