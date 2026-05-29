module MemberPortal
  class EventsController < BaseController
    # El portal no usa Pundit por recurso; la autorización se hace en BaseController
    # mediante authorize @church, :show?. Se exime de los guards globales de Pundit.
    skip_after_action :verify_policy_scoped, only: :index
    skip_after_action :verify_authorized, only: %i[show rsvp]

    before_action :set_event, only: %i[show rsvp]

    def index
      @events = @church.events
        .where(status: %w[scheduled completed])
        .where(visibility: %w[public members_only])
        .upcoming
        .includes(:ministry)

      @my_rsvps = current_member ? EventRsvp.where(member: current_member, event: @events).index_by(&:event_id) : {}
    end

    def show
      @rsvp = current_member ? EventRsvp.find_or_initialize_by(member: current_member, event: @event, church: @church) : nil
    end

    def rsvp
      return redirect_to church_member_portal_event_path(@church, @event), alert: "Debes tener perfil de miembro para confirmar asistencia." unless current_member

      @rsvp = EventRsvp.find_or_initialize_by(member: current_member, event: @event, church: @church)
      @rsvp.assign_attributes(rsvp_params)

      if @rsvp.save
        redirect_to church_member_portal_event_path(@church, @event), notice: "Confirmación actualizada."
      else
        render :show, status: :unprocessable_content
      end
    end

    private

    def set_event
      @event = @church.events
        .where(visibility: %w[public members_only])
        .find_by_public_id!(params[:public_id])
    end

    def rsvp_params
      params.require(:event_rsvp).permit(:status, :guests_count)
    end
  end
end
