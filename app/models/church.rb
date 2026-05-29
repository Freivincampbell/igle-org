class Church < ApplicationRecord
  include PublicIdentifiable

  has_one_attached :logo

  has_many :church_memberships, dependent: :destroy
  has_many :users, through: :church_memberships
  has_many :roles, dependent: :destroy
  has_many :members, dependent: :destroy
  has_many :ministries, dependent: :destroy
  has_many :church_service_times, dependent: :destroy
  has_many :families, dependent: :destroy
  has_many :family_members, dependent: :destroy
  has_many :events, dependent: :destroy
  has_many :event_rsvps, dependent: :destroy
  has_many :event_attendances, dependent: :destroy
  has_many :boards, dependent: :destroy
  has_many :board_members, dependent: :destroy
  has_many :occupations, dependent: :destroy
  has_many :skills, dependent: :destroy
  has_many :member_occupations, dependent: :destroy
  has_many :member_skills, dependent: :destroy
  has_many :profile_change_requests, dependent: :destroy
  has_many :pastoral_notes, dependent: :destroy

  enum :status, { active: "active", inactive: "inactive" }, validate: true

  scope :publicly_visible, -> { where(public_page_enabled: true, status: "active") }

  normalizes :slug, with: ->(value) { value.to_s.strip.downcase.presence }
  normalizes :primary_color, :secondary_color, with: ->(value) { value.to_s.strip.presence }

  validates :name, presence: true
  validates :status, :locale, :time_zone, presence: true
  validates :slug, uniqueness: { case_sensitive: false }, allow_nil: true,
                   format: { with: /\A[a-z0-9](?:[a-z0-9\-]*[a-z0-9])?\z/, message: :invalid_format }
  validates :primary_color, :secondary_color,
            format: { with: /\A#?[0-9A-Fa-f]{6}\z/, message: :invalid_color },
            allow_nil: true

  validate :logo_content_type_allowed
  validate :logo_size_within_limit

  LOGO_ALLOWED_CONTENT_TYPES = %w[image/png image/jpeg image/jpg image/webp].freeze
  LOGO_MAX_SIZE = 5.megabytes

  private

  def logo_content_type_allowed
    return unless logo.attached?

    content_type = logo.blob&.content_type
    return if content_type.blank?
    return if LOGO_ALLOWED_CONTENT_TYPES.include?(content_type)

    errors.add(:logo, :invalid_content_type)
  end

  def logo_size_within_limit
    return unless logo.attached?

    size = logo.blob&.byte_size
    return if size.blank?
    return if size <= LOGO_MAX_SIZE

    errors.add(:logo, :too_large)
  end
end
