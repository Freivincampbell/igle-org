module ChurchAdmin
  class ChurchMembershipsController < BaseController
    before_action :set_church_membership, only: %i[edit update activate deactivate]
    before_action :set_roles, only: %i[new create edit update]

    def index
      authorize ChurchMembership

      @church_memberships = policy_scope(ChurchMembership)
        .where(church: @church)
        .joins(:user)
        .includes(:user, :roles)
        .order("users.email")
    end

    def new
      authorize ChurchMembership

      @user_registration = UserRegistration.new(church: @church)
    end

    def create
      authorize ChurchMembership

      @user_registration = UserRegistration.new(user_registration_params.merge(church: @church))

      if @user_registration.save
        redirect_to church_admin_memberships_path(@church), notice: t("church_admin.memberships.created")
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
      authorize @church_membership
      set_selected_role_public_ids
    end

    def update
      authorize @church_membership

      update = UserAccessUpdate.new(
        church_membership: @church_membership,
        user_attributes: user_attributes_params,
        role_public_ids: church_membership_role_params
      )

      if update.save
        redirect_to church_admin_memberships_path(@church), notice: t("church_admin.memberships.updated")
      else
        update.errors.full_messages.each { |message| @church_membership.errors.add(:base, message) }
        @selected_role_public_ids = update.role_public_ids
        render :edit, status: :unprocessable_content
      end
    end

    def activate
      authorize @church_membership

      @church_membership.active!
      redirect_to church_admin_memberships_path(@church), notice: t("church_admin.memberships.activated")
    end

    def deactivate
      authorize @church_membership

      if last_active_owner?(@church_membership)
        redirect_to church_admin_memberships_path(@church), alert: t("church_admin.memberships.last_owner")
      else
        @church_membership.inactive!
        redirect_to church_admin_memberships_path(@church), notice: t("church_admin.memberships.deactivated")
      end
    end

    private

    def set_church_membership
      @church_membership = @church.church_memberships.find_by_public_id!(params[:public_id])
    end

    def set_roles
      @roles = @church.roles.active.order(:name)
    end

    def church_membership_role_params
      params.fetch(:church_membership, {}).fetch(:role_public_ids, [])
    end

    def user_attributes_params
      params.require(:church_membership).fetch(:user, ActionController::Parameters.new).permit(
        :email,
        :first_name,
        :last_name,
        :access_code,
        :access_code_confirmation
      )
    end

    def set_selected_role_public_ids
      @selected_role_public_ids = @church_membership.roles.active.pluck(:public_id)
    end

    def last_active_owner?(church_membership)
      return false unless church_membership.owner?
      return false unless church_membership.active?

      @church.church_memberships.active.where(owner: true).where.not(id: church_membership.id).none?
    end

    def user_registration_params
      params.require(:church_admin_user_registration).permit(
        :email,
        :first_name,
        :last_name,
        :initial_access,
        :initial_access_confirmation,
        role_public_ids: []
      )
    end
  end
end
