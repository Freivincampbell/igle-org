class BoardMember < ApplicationRecord
  include ChurchScoped
  include PublicIdentifiable
  has_paper_trail skip: %i[updated_at]

  POSITIONS = %w[president vice_president secretary treasurer vocal_1 vocal_2 vocal_3 fiscal].freeze

  belongs_to :board
  belongs_to :member

  enum :status, { active: "active", inactive: "inactive" }, validate: true
  enum :position, POSITIONS.index_with(&:itself), prefix: :as, validate: true

  validates :position, presence: true
  validate :board_in_same_church
  validate :member_in_same_church
  validate :member_is_active

  private

  def board_in_same_church
    return if board.blank? || church.blank?
    return if board.church_id == church_id

    errors.add(:board, :must_belong_to_church)
  end

  def member_in_same_church
    return if member.blank? || church.blank?
    return if member.church_id == church_id

    errors.add(:member, :must_belong_to_church)
  end

  def member_is_active
    return if member.blank?
    return unless member.respond_to?(:active?)
    return if member.active?

    errors.add(:member, :must_be_active)
  end
end
