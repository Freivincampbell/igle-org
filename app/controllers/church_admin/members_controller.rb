module ChurchAdmin
  class MembersController < BaseController
    before_action :set_member, only: %i[show edit update activate deactivate]
    before_action :set_user_options, only: %i[new create edit update]

    def index
      authorize Member

      base = policy_scope(Member).where(church: @church)
      base = base.search_by_name(params[:q]) if params[:q].present?
      base = base.where(member_status: params[:status]) if params[:status].present?

      @pagy, @members = pagy(base.ordered, limit: 25)
    end

    def search
      authorize Member

      query = params[:q].to_s.strip
      @results = if query.length < 2
        Member.none
      else
        policy_scope(Member)
          .where(church: @church)
          .where.not(public_id: Array(params[:exclude]))
          .search_by_name(query)
          .reorder(:last_name, :first_name)
          .limit(10)
      end

      @frame_id = params[:frame_id].to_s.gsub(/[^a-zA-Z0-9_-]/, "").presence || "member-search-results"

      render layout: false
    end

    def show
      authorize @member

      @ministry_memberships = @member.ministry_memberships
        .active
        .includes(:ministry)
        .joins(:ministry)
        .where(ministries: { church_id: @church.id })
        .order("ministries.name")
    end

    def new
      @member = @church.members.new(default_member_attributes)
      authorize @member
    end

    def create
      @member = @church.members.new(member_params)
      authorize @member

      if @member.save
        redirect_to church_admin_member_path(@church, @member), notice: t("church_admin.members.created")
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
      authorize @member
    end

    def update
      authorize @member

      if @member.update(member_params)
        redirect_to church_admin_member_path(@church, @member), notice: t("church_admin.members.updated")
      else
        render :edit, status: :unprocessable_content
      end
    end

    def activate
      authorize @member
      @member.active!

      redirect_to church_admin_member_path(@church, @member), notice: t("church_admin.members.activated")
    end

    def deactivate
      authorize @member
      @member.inactive!

      redirect_to church_admin_member_path(@church, @member), notice: t("church_admin.members.deactivated")
    end

    private

    def set_member
      @member = @church.members.find_by_public_id!(params[:public_id])
    end

    def set_user_options
      @user_options = @church.church_memberships
        .active
        .joins(:user)
        .includes(:user)
        .order("users.email")
        .map { |membership| [ membership.user.email, membership.user_id ] }
    end

    def member_params
      params.require(:member).permit(
        :user_id,
        :first_name,
        :middle_name,
        :last_name,
        :second_last_name,
        :email,
        :phone,
        :secondary_phone,
        :birth_date,
        :gender,
        :marital_status,
        :children_count,
        :baptized_on,
        :official_membership_on,
        :member_status,
        :address_line_1,
        :address_line_2,
        :city,
        :state,
        :postal_code,
        :country,
        :emergency_contact_name,
        :emergency_contact_phone,
        :notes,
        :photo
      )
    end

    def default_member_attributes
      {
        member_status: "active",
        children_count: 0,
        country: @church.country
      }
    end
  end
end
