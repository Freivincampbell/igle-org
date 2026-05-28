class Member < ApplicationRecord
  include ChurchScoped
  include PublicIdentifiable

  belongs_to :user, optional: true
  has_many :ministry_memberships, dependent: :destroy
  has_many :ministries, through: :ministry_memberships
  has_many :family_members, dependent: :destroy
  has_many :families, through: :family_members

  enum :gender, { male: "male", female: "female", not_specified: "not_specified" }, validate: true
  enum :marital_status, {
    single: "single",
    married: "married",
    widowed: "widowed",
    divorced: "divorced",
    separated: "separated",
    other: "other"
  }, validate: true
  enum :member_status, { active: "active", inactive: "inactive" }, validate: true

  normalizes :email, with: ->(email) { email.to_s.strip.downcase.presence }
  normalizes :first_name, :middle_name, :last_name, :second_last_name, with: ->(value) { value.to_s.strip }

  validates :first_name, :last_name, :second_last_name, :phone, :birth_date, presence: true
  validates :gender, :marital_status, :member_status, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :email, uniqueness: { scope: :church_id, case_sensitive: false }, allow_blank: true
  validates :children_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :dates_cannot_be_in_the_future
  validate :user_belongs_to_church

  scope :ordered, -> { order(:last_name, :second_last_name, :first_name) }

  def full_name
    [ first_name, middle_name, last_name, second_last_name ].compact_blank.join(" ")
  end

  private

  def dates_cannot_be_in_the_future
    {
      birth_date:,
      baptized_on:,
      official_membership_on:
    }.each do |attribute, value|
      errors.add(attribute, "no puede estar en el futuro") if value.present? && value.future?
    end
  end

  def user_belongs_to_church
    return if user.blank? || church.blank?
    return if church.church_memberships.exists?(user:)

    errors.add(:user, "debe pertenecer a la iglesia")
  end
end
