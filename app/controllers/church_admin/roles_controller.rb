module ChurchAdmin
  class RolesController < BaseController
    before_action :set_role, only: %i[show edit update activate deactivate update_permissions]
    before_action :set_permissions, only: %i[show edit update update_permissions]

    def index
      authorize Role

      @roles = policy_scope(Role)
        .where(church: @church)
        .order(:name)
    end

    def show
      authorize @role
    end

    def new
      @role = @church.roles.new(status: "active")
      authorize @role
    end

    def create
      @role = @church.roles.new(role_params)
      authorize @role

      if @role.save
        redirect_to church_admin_role_path(@church, @role), notice: t("church_admin.roles.created")
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
      authorize @role
    end

    def update
      authorize @role

      if @role.update(role_params)
        redirect_to church_admin_role_path(@church, @role), notice: t("church_admin.roles.updated")
      else
        render :edit, status: :unprocessable_content
      end
    end

    def activate
      authorize @role
      @role.active!

      redirect_to church_admin_role_path(@church, @role), notice: t("church_admin.roles.activated")
    end

    def deactivate
      authorize @role
      @role.inactive!

      redirect_to church_admin_role_path(@church, @role), notice: t("church_admin.roles.deactivated")
    end

    def update_permissions
      authorize @role, :manage?

      assignment = Permissions::RoleMatrixAssignment.new(
        role: @role,
        permission_public_ids: role_permission_params
      )

      if assignment.save
        redirect_to church_admin_role_path(@church, @role), notice: t("church_admin.roles.permissions_updated")
      else
        assignment.errors.full_messages.each { |message| @role.errors.add(:base, message) }
        render :edit, status: :unprocessable_content
      end
    end

    private

    def set_role
      @role = @church.roles.find_by_public_id!(params[:public_id])
    end

    def set_permissions
      @permissions = Permission.assignable.ordered.to_a
      @selected_permission_public_ids = @role.permissions.pluck(:public_id)
    end

    def role_params
      params.require(:role).permit(:name, :description, :pastoral, :status)
    end

    def role_permission_params
      params.fetch(:role, {}).fetch(:permission_public_ids, [])
    end
  end
end
