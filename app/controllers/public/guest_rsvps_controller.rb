module Public
  class GuestRsvpsController < BaseController
    THROTTLE_LIMIT = 5
    THROTTLE_PERIOD = 10.minutes

    def create
      resolve_public_church!
      @event = @church.events.visibility_public.where(status: "scheduled")
        .find_by_public_id!(params[:event_public_id])

      return redirect_to event_path_for(@event), notice: t("public.guest_rsvps.received") if honeypot_triggered?
      return redirect_to event_path_for(@event), alert: t("public.guest_rsvps.throttled") if throttled?

      registration = Events::GuestRsvpRegistration.new(event: @event, **guest_rsvp_params.to_h.symbolize_keys)

      if registration.save
        redirect_to public_church_guest_rsvp_path(@church.slug, registration.guest_rsvp.access_token),
                    notice: t("public.guest_rsvps.created")
      else
        @guest_rsvp_errors = registration.errors.full_messages
        render "public/events/show", status: :unprocessable_content
      end
    end

    def show
      resolve_public_church!
      resolve_guest_rsvp!
    end

    def update
      resolve_public_church!
      resolve_guest_rsvp!

      if params[:cancel].present?
        @guest_rsvp.update!(status: "cancelled")
        return redirect_to public_church_guest_rsvp_path(@church.slug, @guest_rsvp.access_token),
                           notice: t("public.guest_rsvps.cancelled")
      end

      registration = Events::GuestRsvpRegistration.new(
        event: @guest_rsvp.event, guest_rsvp: @guest_rsvp, **guest_rsvp_params.to_h.symbolize_keys
      )

      if registration.save
        redirect_to public_church_guest_rsvp_path(@church.slug, @guest_rsvp.access_token),
                    notice: t("public.guest_rsvps.updated")
      else
        @guest_rsvp_errors = registration.errors.full_messages
        render :show, status: :unprocessable_content
      end
    end

    private

    def resolve_guest_rsvp!
      @guest_rsvp = EventGuestRsvp.for_church(@church).find_by!(access_token: params[:access_token].to_s)
      @event = @guest_rsvp.event
    end

    def guest_rsvp_params
      params.fetch(:guest_rsvp, {}).permit(:name, :email, :phone, :guests_count)
    end

    def event_path_for(event)
      public_church_event_path(@church.slug, event)
    end

    # Campo oculto para humanos; si viene lleno es un bot. Se responde como
    # éxito para no darle señal.
    def honeypot_triggered?
      params[:website].present?
    end

    def throttled?
      key = "guest_rsvp_throttle:#{@church.id}:#{request.remote_ip}"
      count = Rails.cache.increment(key, 1, expires_in: THROTTLE_PERIOD)
      count.present? && count > THROTTLE_LIMIT
    end
  end
end
