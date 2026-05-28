class Church < ApplicationRecord
  include PublicIdentifiable

  has_one_attached :logo

  has_many :church_memberships, dependent: :destroy
  has_many :users, through: :church_memberships
  has_many :roles, dependent: :destroy
  has_many :members, dependent: :destroy
  has_many :ministries, dependent: :destroy

  enum :status, { active: "active", inactive: "inactive" }, validate: true

  validates :name, presence: true
  validates :status, :locale, :time_zone, presence: true
end
