module PublicIdentifiable
  extend ActiveSupport::Concern

  UUID_FORMAT = /\A[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i

  included do
    validates :public_id, presence: true, uniqueness: true

    before_validation :assign_public_id, on: :create
  end

  class_methods do
    def find_by_public_id!(public_id)
      raise ActiveRecord::RecordNotFound, "#{name} not found" unless public_id.to_s.match?(UUID_FORMAT)

      find_by!(public_id:)
    end
  end

  def to_param
    public_id
  end

  private

  def assign_public_id
    self.public_id ||= SecureRandom.uuid
  end
end
