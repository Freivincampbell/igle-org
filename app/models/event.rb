class Event < ApplicationRecord
  include ChurchScoped
  include PublicIdentifiable
  include PgSearch::Model

  pg_search_scope :search_by_name,
    against: :title,
    using: { tsearch: { prefix: true } }

  EVENT_TYPES = %w[service ministry_meeting wedding baptism retreat special class other].freeze
  VISIBILITIES = %w[public members_only private].freeze
  RECURRENCE_FREQUENCIES = %w[none daily weekly monthly].freeze

  belongs_to :ministry, optional: true
  belongs_to :responsible_member, class_name: "Member", optional: true
  belongs_to :created_by, class_name: "User", optional: true

  has_many :event_rsvps, dependent: :destroy
  has_many :event_guest_rsvps, dependent: :destroy
  has_many :event_attendances, dependent: :destroy

  enum :status, { scheduled: "scheduled", cancelled: "cancelled", completed: "completed" }, validate: true
  enum :event_type, EVENT_TYPES.index_with(&:itself), prefix: :type, validate: true
  enum :visibility, VISIBILITIES.index_with(&:itself), prefix: :visibility, validate: true
  enum :recurrence_frequency, RECURRENCE_FREQUENCIES.index_with(&:itself), prefix: :recurrence, validate: true

  normalizes :title, :location, with: ->(value) { value.to_s.strip.presence }

  validates :title, presence: true
  validates :starts_at, presence: true
  validate :ends_at_after_starts_at
  validate :recurrence_until_after_starts_at
  validate :ministry_belongs_to_church
  validate :responsible_member_belongs_to_church
  validates :capacity, numericality: { greater_than: 0, only_integer: true, allow_nil: true }

  scope :ordered, -> { order(starts_at: :desc) }
  scope :upcoming, -> { where(starts_at: Time.current..).order(:starts_at) }
  scope :past, -> { where(starts_at: ...Time.current).order(starts_at: :desc) }

  def responsible_member_public_id
    responsible_member&.public_id
  end

  def recurring?
    self[:recurring] && recurrence_frequency.present? && recurrence_frequency != "none"
  end

  def confirmed_attendees_count
    @confirmed_attendees_count ||= member_attending_count + member_guests_count + guest_attendees_count
  end

  def member_attending_count
    event_rsvps.where(status: "attending").count
  end

  def member_guests_count
    event_rsvps.where(status: "attending").sum(:guests_count)
  end

  def guest_attendees_count
    event_guest_rsvps.where(status: "attending").sum("guests_count + 1")
  end

  def maybe_count
    event_rsvps.where(status: "maybe").count
  end

  def not_attending_count
    event_rsvps.where(status: "not_attending").count
  end

  def attended_count
    event_attendances.where(attended: true).count
  end

  def present_member_ids
    @present_member_ids ||= event_attendances.where(attended: true).where.not(member_id: nil)
      .distinct.pluck(:member_id).to_set
  end

  def confirmed_member_ids
    @confirmed_member_ids ||= event_rsvps.where(status: "attending").pluck(:member_id).to_set
  end

  def no_show_member_ids
    confirmed_member_ids - present_member_ids
  end

  def spontaneous_count
    member_spontaneous = (present_member_ids - confirmed_member_ids).size
    walk_in_count = event_attendances.where(attended: true, member_id: nil).count
    member_spontaneous + walk_in_count
  end

  def no_show_rate
    return 0 if confirmed_member_ids.empty?

    (no_show_member_ids.size * 100.0 / confirmed_member_ids.size).round
  end

  private

  def ends_at_after_starts_at
    return if ends_at.blank? || starts_at.blank?
    return if ends_at > starts_at

    errors.add(:ends_at, :must_be_after_starts_at)
  end

  def recurrence_until_after_starts_at
    return if recurrence_until.blank? || starts_at.blank?
    return if recurrence_until >= starts_at.to_date

    errors.add(:recurrence_until, :must_be_after_starts_at)
  end

  def ministry_belongs_to_church
    return if ministry.blank? || church.blank?
    return if ministry.church_id == church_id

    errors.add(:ministry, :must_belong_to_church)
  end

  def responsible_member_belongs_to_church
    return if responsible_member.blank? || church.blank?
    return if responsible_member.church_id == church_id

    errors.add(:responsible_member, :must_belong_to_church)
  end
end
