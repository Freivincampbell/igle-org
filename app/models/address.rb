class Address < ApplicationRecord
  include ChurchScoped
  include PublicIdentifiable

  belongs_to :addressable, polymorphic: true

  normalizes :line_1, :line_2, :city, :state, :country, :postal_code,
             with: ->(value) { value.to_s.strip.presence }
end
