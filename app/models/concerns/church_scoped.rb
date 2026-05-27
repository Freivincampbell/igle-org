module ChurchScoped
  extend ActiveSupport::Concern

  included do
    belongs_to :church

    validates :church, presence: true

    scope :for_church, ->(church) { where(church:) }
  end
end
