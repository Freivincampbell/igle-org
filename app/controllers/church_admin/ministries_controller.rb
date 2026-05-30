module ChurchAdmin
  class MinistriesController < BaseController
    before_action :set_ministry, only: %i[show edit update activate deactivate update_members]
    before_action :set_member_assignment_options, only: %i[show update_members]

    def index
      authorize Ministry

      base = policy_scope(Ministry).where(church: @church)
      base = base.search_by_name(params[:q]) if params[:q].present?
      base = base.where(status: params[:status]) if params[:status].present?

      @pagy, @ministries = pagy(base.ordered, limit: 25)
    end

    def show
      authorize @ministry
    end

    def new
      @ministry = @church.ministries.new(status: "active")
      authorize @ministry
    end

    def create
      @ministry = @church.ministries.new(ministry_params)
      authorize @ministry

      if @ministry.save
        redirect_to church_admin_ministry_path(@church, @ministry), notice: t("church_admin.ministries.created")
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
      authorize @ministry
    end

    def update
      authorize @ministry

      if @ministry.update(ministry_params)
        redirect_to church_admin_ministry_path(@church, @ministry), notice: t("church_admin.ministries.updated")
      else
        render :edit, status: :unprocessable_content
      end
    end

    def activate
      authorize @ministry
      @ministry.active!

      redirect_to church_admin_ministry_path(@church, @ministry), notice: t("church_admin.ministries.activated")
    end

    def deactivate
      authorize @ministry
      @ministry.inactive!

      redirect_to church_admin_ministry_path(@church, @ministry), notice: t("church_admin.ministries.deactivated")
    end

    def update_members
      authorize @ministry, :update?

      assignment = Ministries::MemberAssignment.new(
        ministry: @ministry,
        member_public_ids: ministry_member_public_ids,
        member_roles: ministry_member_roles
      )

      if assignment.save
        redirect_to church_admin_ministry_path(@church, @ministry), notice: t("church_admin.ministries.members_updated")
      else
        assignment.errors.full_messages.each { |message| @ministry.errors.add(:base, message) }
        render :show, status: :unprocessable_content
      end
    end

    private

    def set_ministry
      @ministry = @church.ministries.find_by_public_id!(params[:public_id])
    end

    def set_member_assignment_options
      @active_ministry_memberships = @ministry.ministry_memberships.active.includes(:member).index_by do |membership|
        membership.member.public_id
      end
    end

    def ministry_params
      params.require(:ministry).permit(:name, :description, :status)
    end

    def ministry_member_public_ids
      params.fetch(:ministry, {}).fetch(:member_public_ids, [])
    end

    def ministry_member_roles
      params.fetch(:ministry, {}).fetch(:member_roles, {})
    end
  end
end
