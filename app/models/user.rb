class User < ApplicationRecord
  devise :database_authenticatable, :recoverable, :rememberable, :validatable

  has_many :church_memberships, dependent: :destroy
  has_many :churches, through: :church_memberships
  has_many :active_church_memberships, -> { active }, class_name: "ChurchMembership", inverse_of: :user
  has_many :active_churches, through: :active_church_memberships, source: :church

  enum :platform_role, { user: "user", super_admin: "super_admin" }, validate: true
  enum :status, { active: "active", inactive: "inactive" }, validate: true

  normalizes :email, with: ->(email) { email.to_s.strip.downcase }

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :platform_role, :status, presence: true

  def active_for_authentication?
    super && active?
  end

  def inactive_message
    active? ? super : :inactive
  end

  def active_membership_for(church)
    return if church.blank?

    church_memberships.active.find_by(church:)
  end

  def member_of?(church)
    active_membership_for(church).present?
  end
end
