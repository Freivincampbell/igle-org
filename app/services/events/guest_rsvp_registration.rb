module Events
  class GuestRsvpRegistration
    include ActiveModel::Model

    attr_accessor :event, :guest_rsvp, :name, :email, :phone, :guests_count

    validates :event, presence: true
    validate :event_is_open_for_rsvp
    validate :capacity_available

    def save
      return false unless valid?

      record = guest_rsvp || existing_by_email || event.event_guest_rsvps.new(church: event.church)
      record.assign_attributes(name:, email:, phone:, guests_count: normalized_guests_count, status: "attending")

      if record.save
        @guest_rsvp = record
        true
      else
        errors.add(:base, record.errors.full_messages.to_sentence)
        false
      end
    end

    private

    def normalized_guests_count
      guests_count.to_i
    end

    def existing_by_email
      normalized_email = email.to_s.strip.downcase
      return if normalized_email.blank?

      @existing_by_email ||= event.event_guest_rsvps.find_by(email: normalized_email)
    end

    def event_is_open_for_rsvp
      return if event.blank?
      return if event.scheduled? && event.visibility_public?

      errors.add(:base, :event_not_open)
    end

    def capacity_available
      return if event.blank? || event.capacity.blank?

      record = guest_rsvp || existing_by_email
      already_counted = record&.attending? ? record.guests_count + 1 : 0
      requested = normalized_guests_count + 1

      return if event.confirmed_attendees_count - already_counted + requested <= event.capacity

      errors.add(:base, :no_capacity)
    end
  end
end
