module ChurchAdmin
  class EventsController < BaseController
    before_action :set_event, only: %i[show edit update cancel reschedule attendance update_attendance]
    before_action :set_form_options, only: %i[new create edit update]

    def index
      authorize Event

      base = policy_scope(Event).where(church: @church)
      base = base.search_by_name(params[:q]) if params[:q].present?

      @filter = params[:filter].presence || "upcoming"
      filtered = case @filter
      when "past" then base.past
      when "all"  then base.ordered
      else             base.upcoming
      end

      @pagy, @events = pagy(filtered, limit: 25)
    end

    def show
      authorize @event
      @rsvps = @event.event_rsvps.includes(:member)
      @attendances = @event.event_attendances.includes(:member)
      @guest_rsvps = @event.event_guest_rsvps.where(status: "attending").order(:name)
    end

    def new
      @event = @church.events.new(default_event_attributes)
      authorize @event
    end

    def create
      @event = @church.events.new(event_params)
      @event.created_by = current_user
      @event.responsible_member = resolve_responsible_member
      authorize @event

      if @event.save
        redirect_to church_admin_event_path(@church, @event), notice: t("church_admin.events.created")
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
      authorize @event
    end

    def update
      authorize @event

      @event.assign_attributes(event_params)
      @event.responsible_member = resolve_responsible_member

      if @event.save
        redirect_to church_admin_event_path(@church, @event), notice: t("church_admin.events.updated")
      else
        render :edit, status: :unprocessable_content
      end
    end

    def cancel
      authorize @event, :deactivate?
      @event.cancelled!
      redirect_to church_admin_event_path(@church, @event), notice: t("church_admin.events.cancelled")
    end

    def reschedule
      authorize @event, :activate?
      @event.scheduled!
      redirect_to church_admin_event_path(@church, @event), notice: t("church_admin.events.rescheduled")
    end

    def attendance
      authorize @event, :update?
      @members = @church.members.active.ordered
      @attendances_by_member = @event.event_attendances.includes(:member).index_by(&:member_id)
      @confirmed_member_ids = @event.event_rsvps.where(status: "attending").pluck(:member_id).to_set
    end

    def update_attendance
      authorize @event, :update?

      attended_public_ids = Array(params.dig(:attendance, :member_ids)).map(&:to_s)

      Event.transaction do
        @church.members.active.find_each do |member|
          attendance = @event.event_attendances.find_or_initialize_by(member:, church: @church)
          if attended_public_ids.include?(member.public_id)
            attendance.attended = true
            attendance.checked_in_at ||= Time.current
            attendance.checked_in_by ||= current_user
            attendance.save!
          elsif attendance.persisted?
            attendance.destroy!
          end
        end
      end

      redirect_to attendance_church_admin_event_path(@church, @event), notice: t("church_admin.events.attendance_updated")
    end

    private

    def set_event
      @event = @church.events.find_by_public_id!(params[:public_id])
    end

    def set_form_options
      @ministry_options = @church.ministries.where(status: "active").order(:name).pluck(:name, :id)
      @member_options = @church.members.active.ordered.map { |m| [ m.full_name, m.public_id ] }
    end

    def resolve_responsible_member
      public_id = params.dig(:event, :responsible_member_public_id)
      return nil if public_id.blank?

      @church.members.find_by_public_id!(public_id)
    end

    def event_params
      params.require(:event).permit(
        :title,
        :description,
        :event_type,
        :location,
        :starts_at,
        :ends_at,
        :visibility,
        :status,
        :ministry_id,
        :recurring,
        :recurrence_frequency,
        :recurrence_until,
        :capacity,
        :food_expected
      )
    end

    def default_event_attributes
      {
        event_type: "service",
        visibility: "members_only",
        status: "scheduled",
        recurrence_frequency: "none"
      }
    end
  end
end
