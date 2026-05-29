module ChurchAdmin
  class FamiliesController < BaseController
    before_action :set_family, only: %i[show edit update activate deactivate update_members]
    before_action :set_member_options, only: %i[show update_members]

    def index
      authorize Family

      @families = policy_scope(Family)
        .where(church: @church)
        .includes(:members)
        .ordered
    end

    def show
      authorize @family
    end

    def new
      @family = @church.families.new(status: "active")
      authorize @family
    end

    def create
      @family = @church.families.new(family_params)
      authorize @family

      if @family.save
        redirect_to church_admin_family_path(@church, @family), notice: t("church_admin.families.created")
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
      authorize @family
    end

    def update
      authorize @family

      if @family.update(family_params)
        redirect_to church_admin_family_path(@church, @family), notice: t("church_admin.families.updated")
      else
        render :edit, status: :unprocessable_content
      end
    end

    def activate
      authorize @family
      @family.active!
      redirect_to church_admin_family_path(@church, @family), notice: t("church_admin.families.activated")
    end

    def deactivate
      authorize @family
      @family.inactive!
      redirect_to church_admin_family_path(@church, @family), notice: t("church_admin.families.deactivated")
    end

    def update_members
      authorize @family, :update?

      assignment = Families::MemberAssignment.new(
        family: @family,
        member_public_ids: params.dig(:family, :member_public_ids) || [],
        member_relationships: params.dig(:family, :member_relationships)&.to_unsafe_h || {},
        primary_contact_public_id: params.dig(:family, :primary_contact_public_id)
      )

      if assignment.save
        redirect_to church_admin_family_path(@church, @family), notice: t("church_admin.families.members_updated")
      else
        assignment.errors.full_messages.each { |m| @family.errors.add(:base, m) }
        render :show, status: :unprocessable_content
      end
    end

    private

    def set_family
      @family = @church.families.find_by_public_id!(params[:public_id])
    end

    def set_member_options
      @current_family_members = @family.family_members.includes(:member).index_by { |fm| fm.member.public_id }
    end

    def family_params
      params.require(:family).permit(:name, :notes, :status)
    end
  end
end
