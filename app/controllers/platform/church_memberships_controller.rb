module Platform
  class ChurchMembershipsController < BaseController
    before_action :set_church

    def new
      authorize ChurchMembership
      @owner_assignment = OwnerAssignment.new(church: @church)
    end

    def create
      authorize ChurchMembership
      @owner_assignment = OwnerAssignment.new(owner_assignment_params.merge(church: @church))

      if @owner_assignment.save
        redirect_to platform_church_path(@church), notice: t("platform.church_memberships.owner_assigned")
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def set_church
      @church = Church.find_by_public_id!(params[:church_public_id])
    end

    def owner_assignment_params
      params.require(:platform_owner_assignment).permit(
        :email,
        :first_name,
        :last_name,
        :password,
        :password_confirmation
      )
    end
  end
end
