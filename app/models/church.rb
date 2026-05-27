class Church < ApplicationRecord
  UUID_FORMAT = /\A[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i

  has_one_attached :logo

  has_many :church_memberships, dependent: :destroy
  has_many :users, through: :church_memberships
  has_many :roles, dependent: :destroy

  enum :status, { active: "active", inactive: "inactive" }, validate: true

  validates :name, presence: true
  validates :public_id, presence: true, uniqueness: true
  validates :status, :locale, :time_zone, presence: true

  before_validation :assign_public_id, on: :create

  def to_param
    public_id
  end

  def self.find_by_public_id!(public_id)
    raise ActiveRecord::RecordNotFound, "Church not found" unless public_id.to_s.match?(UUID_FORMAT)

    find_by!(public_id:)
  end

  private

  def assign_public_id
    self.public_id ||= SecureRandom.uuid
  end
end
