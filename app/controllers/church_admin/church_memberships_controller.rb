module ChurchAdmin
  class ChurchMembershipsController < BaseController
    before_action :set_church_membership, only: %i[edit update]
    before_action :set_roles, only: %i[index edit update]

    def index
      authorize ChurchMembership

      @church_memberships = policy_scope(ChurchMembership)
        .where(church: @church)
        .joins(:user)
        .includes(:user, :roles)
        .order("users.email")
    end

    def edit
      authorize @church_membership
    end

    def update
      authorize @church_membership

      assignment = Permissions::MembershipRoleAssignment.new(
        church_membership: @church_membership,
        role_public_ids: church_membership_role_params
      )

      if assignment.save
        redirect_to church_admin_memberships_path(@church), notice: t("church_admin.memberships.roles_updated")
      else
        assignment.errors.full_messages.each { |message| @church_membership.errors.add(:base, message) }
        render :edit, status: :unprocessable_content
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
  end
end
