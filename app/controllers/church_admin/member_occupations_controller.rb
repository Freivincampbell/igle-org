module ChurchAdmin
  class MemberOccupationsController < BaseController
    before_action :set_member
    before_action :set_member_occupation, only: %i[edit update destroy]

    def assign
      authorize_member_update

      names         = Array(params[:occupation_names]).map(&:strip).reject(&:blank?).uniq
      offers_names  = Array(params[:offers_services])
      looking_names = Array(params[:looking_for_work])

      ActiveRecord::Base.transaction do
        kept_ids = names.map { |n| @church.occupations.find_or_create_by!(name: n) { |o| o.status = "active" }.id }
        @member.member_occupations.where.not(occupation_id: kept_ids).destroy_all

        names.each do |name|
          occupation = @church.occupations.find_or_create_by!(name: name) { |o| o.status = "active" }
          mo = @member.member_occupations.find_or_initialize_by(occupation: occupation, church: @church)
          mo.employment_status = "employed" if mo.new_record?
          mo.offers_services   = offers_names.include?(name)
          mo.looking_for_work  = looking_names.include?(name)
          mo.save!
        end
      end

      redirect_to church_admin_member_path(@church, @member), notice: t("church_admin.member_occupations.updated")
    end

    def new
      @member_occupation = @member.member_occupations.new(church: @church, employment_status: "employed", current: true)
      authorize_member_update
    end

    def create
      @member_occupation = @member.member_occupations.new(member_occupation_params.merge(church: @church))
      authorize_member_update

      if @member_occupation.save
        redirect_to church_admin_member_path(@church, @member), notice: t("church_admin.member_occupations.created")
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
      authorize_member_update
    end

    def update
      authorize_member_update

      if @member_occupation.update(member_occupation_params)
        redirect_to church_admin_member_path(@church, @member), notice: t("church_admin.member_occupations.updated")
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      authorize_member_update

      @member_occupation.destroy
      redirect_to church_admin_member_path(@church, @member), notice: t("church_admin.member_occupations.removed")
    end

    private

    def set_member
      # assign action uses :public_id (member route); nested resources use :member_public_id
      @member = @church.members.find_by_public_id!(params[:public_id].presence || params[:member_public_id])
    end

    def set_member_occupation
      @member_occupation = @member.member_occupations.find_by_public_id!(params[:public_id])
    end

    def authorize_member_update
      authorize @member, :update?
    end

    def member_occupation_params
      params.require(:member_occupation).permit(
        :occupation_id, :company_name, :job_title, :employment_status, :work_type,
        :looking_for_work, :offers_services, :available_for_projects,
        :years_of_experience, :professional_contact, :profile_url,
        :description, :current, :public_in_directory
      )
    end
  end
end
